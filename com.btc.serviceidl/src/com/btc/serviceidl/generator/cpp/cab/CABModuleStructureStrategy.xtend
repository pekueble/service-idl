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
package com.btc.serviceidl.generator.cpp.cab

import com.btc.serviceidl.generator.common.ArtifactNature
import com.btc.serviceidl.generator.common.GeneratorUtil
import com.btc.serviceidl.generator.common.ParameterBundle
import com.btc.serviceidl.generator.common.ProjectType
import com.btc.serviceidl.generator.cpp.IModuleStructureStrategy
import com.btc.serviceidl.generator.cpp.prins.ReferenceResolver
import com.btc.serviceidl.idl.ModuleDeclaration
import org.eclipse.core.runtime.Path

class CABModuleStructureStrategy implements IModuleStructureStrategy
{

    override getIncludeFilePath(Iterable<ModuleDeclaration> module_stack, ProjectType project_type, String baseName)
    {
        // TODO remove MODULES_HEADER_PATH_PREFIX here, and add a method to IModuleStructureStrategy that determines that
        new Path(ReferenceResolver.MODULES_HEADER_PATH_PREFIX).append(
            GeneratorUtil.asPath(ParameterBundle.createBuilder(module_stack).with(project_type).build,
                ArtifactNature.CPP)).append(if (project_type == ProjectType.PROTOBUF) "gen" else "include").append(
            baseName).addFileExtension(if (project_type == ProjectType.PROTOBUF) "pb.h" else "h")
    }

    override getEncapsulationHeaders()
    {
        new Pair('#include <Commons/Core/include/BeginCABHeader.h>', '#include <Commons/Core/include/EndCABHeader.h>')
    }

}
