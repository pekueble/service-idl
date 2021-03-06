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
package com.btc.serviceidl.generator.cpp.prins

import com.btc.serviceidl.generator.common.ArtifactNature
import com.btc.serviceidl.generator.common.GeneratorUtil
import com.btc.serviceidl.generator.common.ParameterBundle
import com.btc.serviceidl.generator.common.TransformType
import com.btc.serviceidl.generator.cpp.IProjectReference
import com.btc.serviceidl.generator.cpp.IProjectSet
import java.util.HashMap
import java.util.UUID
import org.eclipse.core.runtime.IPath
import org.eclipse.xtend.lib.annotations.Data

class VSSolution implements IProjectSet
{
    val vsProjects = new HashMap<String, Entry>

    @Data
    private static class Entry
    {
        UUID uuid
        IPath path
    }

    override String getVcxprojName(ParameterBundle paramBundle)
    {
        var projectName = GeneratorUtil.getTransformedModuleName(paramBundle, ArtifactNature.CPP,
            TransformType.PACKAGE)
        val projectPath = makeProjectPath(paramBundle, projectName)
        ensureEntryExists(projectName, projectPath)
        return projectName
    }

    protected def ensureEntryExists(String projectName, IPath projectPath)
    {
        if (!vsProjects.containsKey(projectName))
        {
            val guid = UUID.nameUUIDFromBytes(projectName.bytes)
            vsProjects.put(projectName, new Entry(guid, projectPath))
        }
        else
        {
            val entry = vsProjects.get(projectName)
            if (!entry.path.equals(projectPath))
            {
                throw new IllegalArgumentException(
                    "Project path inconsistency: existing entry has " + entry.path + ", new value is " + projectPath)
            }
        }
    }

    def String getVcxprojGUID(ProjectReference projectReference)
    {
        return vsProjects.get(projectReference.projectName).uuid.toString.toUpperCase
    }

    @Deprecated
    def resolve(String projectName, IPath projectPath)
    {
        // TODO this depends on the implementation of ProjectGeneratorBaseBase.getProjectPath
        // TODO check if the else branch is valid
        var effectiveProjectPath = if (projectPath.segment(0) ==
                PrinsModuleStructureStrategy.MODULES_HEADER_PATH_PREFIX)
                projectPath.removeFirstSegments(1)
            else
                projectPath
        ensureEntryExists(projectName, makeProjectPath(effectiveProjectPath, projectName))
        new ProjectReference(projectName)
    }

    override ProjectReference resolve(ParameterBundle paramBundle)
    {
        new ProjectReference(getVcxprojName(paramBundle))
    }

    @Data
    static class ProjectReference implements IProjectReference
    {
        val String projectName
    }

    def getVcxProjPath(ProjectReference projectName)
    {
        vsProjects.get(projectName.projectName).path
    }

    private static def IPath makeProjectPath(ParameterBundle paramBundle, String projectName)
    {
        makeProjectPath(GeneratorUtil.asPath(paramBundle, ArtifactNature.CPP), projectName)
    }

    private static def IPath makeProjectPath(IPath projectPath, String projectName)
    {
        projectPath.append(projectName)
    }
}
