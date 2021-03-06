/*********************************************************************
 * \author see AUTHORS file
 * \copyright 2015-2018 BTC Business Technology Consulting AG and others
 * 
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 * 
 * SPDX-License-Identifier: EPL-2.0
 **********************************************************************/
package com.btc.serviceidl.generator.cpp

import com.btc.serviceidl.generator.common.ArtifactNature
import com.btc.serviceidl.generator.common.GeneratorUtil
import com.btc.serviceidl.generator.common.Names
import com.btc.serviceidl.generator.common.ParameterBundle
import com.btc.serviceidl.generator.common.ProjectType
import com.btc.serviceidl.generator.common.ProtobufType
import com.btc.serviceidl.generator.common.ResolvedName
import com.btc.serviceidl.generator.common.TransformType
import com.btc.serviceidl.idl.AbstractContainerDeclaration
import com.btc.serviceidl.idl.AbstractType
import com.btc.serviceidl.idl.AbstractTypeReference
import com.btc.serviceidl.idl.FunctionDeclaration
import com.btc.serviceidl.idl.InterfaceDeclaration
import com.btc.serviceidl.idl.MemberElement
import com.btc.serviceidl.idl.PrimitiveType
import com.btc.serviceidl.util.Constants
import com.google.common.base.CaseFormat
import java.util.Optional

import static extension com.btc.serviceidl.generator.common.GeneratorUtil.*
import static extension com.btc.serviceidl.util.Util.*

class ProtobufUtil
{
    static def ResolvedName resolveProtobuf(extension TypeResolver typeResolver, AbstractTypeReference object,
        ProtobufType protobufType)
    {
        if (object.isUUIDType)
            return new ResolvedName(resolveSymbol("std::string"), TransformType.NAMESPACE)
        else if (object.isInt16 || object.isByte || object.isChar)
            return new ResolvedName("::google::protobuf::int32", TransformType.NAMESPACE)
        else if (object instanceof PrimitiveType)
            return new ResolvedName(getPrimitiveTypeName(object), TransformType.NAMESPACE)
        else if (object instanceof AbstractType && (object as AbstractType).primitiveType !== null)
            return resolveProtobuf(typeResolver, (object as AbstractType).primitiveType, protobufType)

        val scopeDeterminant = object.scopeDeterminant

        val paramBundle = ParameterBundle.createBuilder(scopeDeterminant.moduleStack).with(ProjectType.PROTOBUF).build

        // TODO this is cloned by java.ProtobufUtil(.getLocalName?) 
        val result = GeneratorUtil.getTransformedModuleName(paramBundle, ArtifactNature.CPP, TransformType.NAMESPACE) +
            Constants.SEPARATOR_NAMESPACE + if (object instanceof InterfaceDeclaration)
                Names.plain(object) + protobufType.getName
            else if (object instanceof FunctionDeclaration)
                Names.plain(scopeDeterminant) + "_" + protobufType.getName + "_" + Names.plain(object) +
                    protobufType.getName
            else
                Names.plain(object)

        addTargetInclude(typeResolver.moduleStructureStrategy.getIncludeFilePath(
            scopeDeterminant.moduleStack,
            ProjectType.PROTOBUF,
            GeneratorUtil.getPbFileName(scopeDeterminant),
            HeaderType.PROTOBUF_HEADER
        ))

        object.resolveProjectFilePath(ProjectType.PROTOBUF)
        return new ResolvedName(result, TransformType.NAMESPACE)
    }

    static def String resolveDecode(extension TypeResolver typeResolver, ParameterBundle paramBundle,
        AbstractTypeReference element, AbstractContainerDeclaration container)
    {
        resolveDecode(typeResolver, paramBundle, element, container, true)
    }

    static def String resolveDecode(extension TypeResolver typeResolver, ParameterBundle paramBundle,
        AbstractTypeReference element, AbstractContainerDeclaration container, boolean useCodecNs)
    {
        // handle sequence first, because it may include UUIDs and other types from below
        if (element.isSequenceType)
        {
            val isFailable = element.isFailable
            val ultimateType = element.ultimateType

            // TODO remove ProtobufType argument
            var protobufType = typeResolver.resolveProtobuf(ultimateType, ProtobufType.REQUEST).fullyQualifiedName
            if (isFailable)
                protobufType = typeResolver.resolveFailableProtobufType(element, container)
            else if (ultimateType.isByte || ultimateType.isInt16 || ultimateType.isChar)
                protobufType = "google::protobuf::int32"

            val isUUIDType = ultimateType.isUUIDType
            val decodeMethodName = (if (isFailable)
                "DecodeFailable"
            else if (isUUIDType) "DecodeUUID" else "Decode") +
                if (element.eContainer instanceof AbstractType &&
                    (element.eContainer as AbstractType).collectionType !== null &&
                    element.eContainer.eContainer instanceof MemberElement)
                    "ToVector"
                else
                    ""

            return '''«IF useCodecNs»«typeResolver.resolveCodecNS(paramBundle, ultimateType, isFailable, Optional.of(container))»::«ENDIF»«decodeMethodName»«IF isFailable || !isUUIDType»< «protobufType», «resolve(ultimateType)» >«ENDIF»'''
        }

        if (element.isUUIDType)
            return '''«typeResolver.resolveCodecNS(paramBundle, element)»::DecodeUUID'''

        if (element.isByte)
            return '''static_cast<«resolveSymbol("int8_t")»>'''

        if (element.isInt16)
            return '''static_cast<«resolveSymbol("int16_t")»>'''

        if (element.isChar)
            return '''static_cast<char>'''

        return '''«typeResolver.resolveCodecNS(paramBundle, element)»::Decode'''
    }

    static def String resolveCodecNS(TypeResolver typeResolver, ParameterBundle paramBundle,
        AbstractTypeReference object)
    {
        resolveCodecNS(typeResolver, paramBundle, object, false, Optional.empty)
    }

    static def String resolveCodecNS(extension TypeResolver typeResolver, ParameterBundle paramBundle,
        AbstractTypeReference object, boolean isFailable, Optional<AbstractContainerDeclaration> container)
    {
        val ultimateType = object.ultimateType

        // failable wrappers always local!
        val moduleStack = if (isFailable) paramBundle.moduleStack else ultimateType.scopeDeterminant.moduleStack

        val codecName = GeneratorUtil.getCodecName(if (isFailable) container.get else ultimateType.scopeDeterminant)

        addTargetInclude(
            typeResolver.moduleStructureStrategy.getIncludeFilePath(moduleStack, ProjectType.PROTOBUF, codecName,
                HeaderType.REGULAR_HEADER))

        resolveProjectFilePath(ultimateType, ProjectType.PROTOBUF)

        GeneratorUtil.getTransformedModuleName(
            new ParameterBundle.Builder().with(moduleStack).with(ProjectType.PROTOBUF).build, ArtifactNature.CPP,
            TransformType.NAMESPACE) + TransformType.NAMESPACE.separator + codecName
    }

    static def String resolveFailableProtobufType(extension TypeResolver typeResolver, AbstractTypeReference element,
        AbstractContainerDeclaration container)
    {
        // TODO isn't there a specific type that is used from that library? Is it really required?
        // explicitly include some essential dependencies
        typeResolver.addLibraryDependency(new ExternalDependency("BTC.CAB.ServiceComm.Default"))

        return GeneratorUtil.getTransformedModuleName(
            ParameterBundle.createBuilder(container.scopeDeterminant.moduleStack).with(ProjectType.PROTOBUF).build,
            ArtifactNature.CPP,
            TransformType.NAMESPACE
        ) + Constants.SEPARATOR_NAMESPACE + GeneratorUtil.asFailable(element, container, qualifiedNameProvider)
    }

    static def asCppProtobufName(String name)
    {
        name.asProtobufName(CaseFormat.LOWER_UNDERSCORE)
    }
}
