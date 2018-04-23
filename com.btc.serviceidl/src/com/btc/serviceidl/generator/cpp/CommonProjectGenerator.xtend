/**
 * \author see AUTHORS file
 * \copyright 2015-2018 BTC Business Technology Consulting AG and others
 * 
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 * 
 * SPDX-License-Identifier: EPL-2.0
 */
package com.btc.serviceidl.generator.cpp

import com.btc.serviceidl.generator.common.GeneratorUtil
import com.btc.serviceidl.generator.common.ProjectType
import com.btc.serviceidl.generator.common.TransformType
import com.btc.serviceidl.idl.IDLSpecification
import com.btc.serviceidl.idl.ModuleDeclaration
import com.btc.serviceidl.util.Constants
import java.util.Collection
import java.util.HashMap
import java.util.Map
import java.util.Optional
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.scoping.IScopeProvider

import static extension com.btc.serviceidl.generator.common.FileTypeExtensions.*

@Accessors(PROTECTED_GETTER)
class CommonProjectGenerator extends ProjectGeneratorBaseBase
{
    new(Resource resource, IFileSystemAccess file_system_access, IQualifiedNameProvider qualified_name_provider,
        IScopeProvider scope_provider, IDLSpecification idl, VSSolution vsSolution,
        Map<String, HashMap<String, String>> protobuf_project_references,
        Map<EObject, Collection<EObject>> smart_pointer_map, ModuleDeclaration module)
    {
        super(resource, file_system_access, qualified_name_provider, scope_provider, idl, vsSolution,
            protobuf_project_references, smart_pointer_map, ProjectType.COMMON, module)
    }

    // TODO this is largely a clone of ProjectGeneratorBase.generateProjectStructure
    def generate()
    {
        param_bundle.reset(com.btc.serviceidl.util.Util.getModuleStack(module))

        // paths
        val include_path = projectPath + "include" + Constants.SEPARATOR_FILE
        val source_path = projectPath + "source" + Constants.SEPARATOR_FILE

        // file names
        val export_header_file_name = (GeneratorUtil.transform(param_bundle.build, TransformType.EXPORT_HEADER) +
            "_export".h).toLowerCase
        val header_file = Constants.FILE_NAME_TYPES.h
        val cpp_file = Constants.FILE_NAME_TYPES.cpp
        val dependency_file_name = Constants.FILE_NAME_DEPENDENCIES.cpp

        // sub-folder "./include"
        reinitializeFile()
        file_system_access.generateFile(include_path + export_header_file_name, generateExportHeader())
        header_files.add(export_header_file_name)

        reinitializeFile()
        file_system_access.generateFile(include_path + header_file,
            generateHFileCommons(module, export_header_file_name))
        header_files.add(header_file)

        // sub-folder "./source"
        reinitializeFile()
        file_system_access.generateFile(source_path + cpp_file, generateCppCommons(module, export_header_file_name))
        cpp_files.add(cpp_file)

        reinitializeFile()
        file_system_access.generateFile(source_path + dependency_file_name, generateDependencies)
        dependency_files.add(dependency_file_name)

        generateVSProjectFiles(ProjectType.COMMON, projectPath, vsSolution.getVcxprojName(param_bundle, Optional.empty))
    }

    def private String generateHFileCommons(ModuleDeclaration module, String export_header)
    {
        val file_content = new CommonsGenerator(typeResolver, param_bundle, idl).generateHeaderFileBody(module,
            export_header)
        generateHeader(file_content.toString, Optional.of(export_header))
    }

    def private String generateCppCommons(ModuleDeclaration module, String export_header)
    {
        reinitializeFile

        val file_content = new CommonsGenerator(typeResolver, param_bundle, idl).generateImplFileBody(module,
            export_header)
        generateSource(file_content.toString, Optional.empty)
    }

}
