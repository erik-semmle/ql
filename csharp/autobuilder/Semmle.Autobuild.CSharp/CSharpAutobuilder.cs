﻿using Semmle.Extraction.CSharp;
using Semmle.Util.Logging;
using Semmle.Autobuild.Shared;
using Semmle.Util;
using System.Linq;

namespace Semmle.Autobuild.CSharp
{
    /// <summary>
    /// Encapsulates C# build options.
    /// </summary>
    public class CSharpAutobuildOptions : AutobuildOptionsShared
    {
        private const string extractorOptionPrefix = "CODEQL_EXTRACTOR_CSHARP_OPTION_";

        public bool Buildless { get; }

        public override Language Language => Language.CSharp;


        /// <summary>
        /// Reads options from environment variables.
        /// Throws ArgumentOutOfRangeException for invalid arguments.
        /// </summary>
        public CSharpAutobuildOptions(IBuildActions actions) : base(actions)
        {
            Buildless = actions.GetEnvironmentVariable(lgtmPrefix + "BUILDLESS").AsBool("buildless", false) ||
                actions.GetEnvironmentVariable(extractorOptionPrefix + "BUILDLESS").AsBool("buildless", false);
        }
    }

    public class CSharpAutobuilder : Autobuilder<CSharpAutobuildOptions>
    {
        private const string buildCommandDocsUrl =
            "https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors/configuring-the-codeql-workflow-for-compiled-languages";

        private DotNetRule? dotNetRule;

        private MsBuildRule? msBuildRule;

        private BuildCommandAutoRule? buildCommandAutoRule;

        private readonly DiagnosticClassifier diagnosticClassifier;

        protected override DiagnosticClassifier DiagnosticClassifier => diagnosticClassifier;

        public CSharpAutobuilder(IBuildActions actions, CSharpAutobuildOptions options) : base(actions, options) =>
            diagnosticClassifier = new CSharpDiagnosticClassifier();

        public override BuildScript GetBuildScript()
        {
            /// <summary>
            /// A script that checks that the C# extractor has been executed.
            /// </summary>
            BuildScript CheckExtractorRun(bool warnOnFailure) =>
                BuildScript.Create(actions =>
                {
                    if (actions.FileExists(Extractor.GetCSharpLogPath()))
                        return 0;

                    if (warnOnFailure)
                        Log(Severity.Error, "No C# code detected during build.");

                    return 1;
                });

            var attempt = BuildScript.Failure;
            switch (GetCSharpBuildStrategy())
            {
                case CSharpBuildStrategy.CustomBuildCommand:
                    attempt = new BuildCommandRule(DotNetRule.WithDotNet).Analyse(this, false) & CheckExtractorRun(true);
                    break;
                case CSharpBuildStrategy.Buildless:
                    // No need to check that the extractor has been executed in buildless mode
                    attempt = new StandaloneBuildRule().Analyse(this, false);
                    break;
                case CSharpBuildStrategy.MSBuild:
                    attempt = new MsBuildRule().Analyse(this, false) & CheckExtractorRun(true);
                    break;
                case CSharpBuildStrategy.DotNet:
                    attempt = new DotNetRule().Analyse(this, false) & CheckExtractorRun(true);
                    break;
                case CSharpBuildStrategy.Auto:
                    var cleanTrapFolder =
                        BuildScript.DeleteDirectory(TrapDir);
                    var cleanSourceArchive =
                        BuildScript.DeleteDirectory(SourceArchiveDir);
                    var tryCleanExtractorArgsLogs =
                        BuildScript.Create(actions =>
                        {
                            foreach (var file in Extractor.GetCSharpArgsLogs())
                            {
                                try
                                {
                                    actions.FileDelete(file);
                                }
                                catch // lgtm[cs/catch-of-all-exceptions] lgtm[cs/empty-catch-block]
                                { }
                            }

                            return 0;
                        });
                    var attemptExtractorCleanup =
                        BuildScript.Try(cleanTrapFolder) &
                        BuildScript.Try(cleanSourceArchive) &
                        tryCleanExtractorArgsLogs &
                        BuildScript.DeleteFile(Extractor.GetCSharpLogPath());

                    /// <summary>
                    /// Execute script `s` and check that the C# extractor has been executed.
                    /// If either fails, attempt to cleanup any artifacts produced by the extractor,
                    /// and exit with code 1, in order to proceed to the next attempt.
                    /// </summary>
                    BuildScript IntermediateAttempt(BuildScript s) =>
                        (s & CheckExtractorRun(false)) |
                        (attemptExtractorCleanup & BuildScript.Failure);

                    this.dotNetRule = new DotNetRule();
                    this.msBuildRule = new MsBuildRule();
                    this.buildCommandAutoRule = new BuildCommandAutoRule(DotNetRule.WithDotNet);

                    attempt =
                        // First try .NET Core
                        IntermediateAttempt(dotNetRule.Analyse(this, true)) |
                        // Then MSBuild
                        (() => IntermediateAttempt(msBuildRule.Analyse(this, true))) |
                        // And finally look for a script that might be a build script
                        (() => this.buildCommandAutoRule.Analyse(this, true) & CheckExtractorRun(true)) |
                        // All attempts failed: print message
                        AutobuildFailure();
                    break;
            }

            return attempt;
        }

        protected override void AutobuildFailureDiagnostic()
        {
            // if `ScriptPath` is not null here, the `BuildCommandAuto` rule was
            // run and found at least one script to execute
            if (this.buildCommandAutoRule is not null &&
                this.buildCommandAutoRule.ScriptPath is not null)
            {
                DiagnosticMessage message;

                // if we found multiple build scripts in the project directory, then we can say
                // as much to indicate that we may have picked the wrong one;
                // otherwise, we just report that the one script we found didn't work
                if (this.buildCommandAutoRule.CandidatePaths.Count() > 1)
                {
                    message = MakeDiagnostic("multiple-build-scripts", "There are multiple potential build scripts");
                    message.MarkdownMessage =
                        "CodeQL found multiple potential build scripts for your project and " +
                        $"attempted to run `{buildCommandAutoRule.ScriptPath}`, which failed. " +
                        "This may not be the right build script for your project. " +
                        $"Set up a [manual build command]({buildCommandDocsUrl}).";
                }
                else
                {
                    message = MakeDiagnostic("script-failure", "Unable to build project using build script");
                    message.MarkdownMessage =
                        "CodeQL attempted to build your project using a script located at " +
                        $"`{buildCommandAutoRule.ScriptPath}`, which failed. " +
                        $"Set up a [manual build command]({buildCommandDocsUrl}).";
                }

                message.Severity = DiagnosticMessage.TspSeverity.Error;
                AddDiagnostic(message);
            }

            // both dotnet and msbuild builds require project or solution files; if we haven't found any
            // then neither of those rules would've worked
            if (this.ProjectsOrSolutionsToBuild.Count == 0)
            {
                var message = MakeDiagnostic("no-projects-or-solutions", "No project or solutions files found");
                message.PlaintextMessage =
                    "CodeQL could not find any project or solution files in your repository. " +
                    $"Set up a [manual build command]({buildCommandDocsUrl}).";
                message.Severity = DiagnosticMessage.TspSeverity.Error;

                AddDiagnostic(message);
            }
            else if (dotNetRule is not null && dotNetRule.NotDotNetProjects.Any())
            {
                var message = MakeDiagnostic("dotnet-incompatible-projects", "Some projects are incompatible with .NET Core");
                message.MarkdownMessage =
                    "CodeQL found some projects which cannot be built with .NET Core:\n" +
                    string.Join('\n', dotNetRule.NotDotNetProjects.Select(p => $"- `{p.FullPath}`"));
                message.Severity = DiagnosticMessage.TspSeverity.Warning;

                AddDiagnostic(message);
            }

            // report any projects that failed to build with .NET Core
            if (dotNetRule is not null && dotNetRule.FailedProjectsOrSolutions.Any())
            {
                var message = MakeDiagnostic("dotnet-build-failure", "Some projects or solutions failed to build using .NET Core");
                message.MarkdownMessage =
                    "CodeQL was unable to build the following projects using .NET Core:\n" +
                    string.Join('\n', dotNetRule.FailedProjectsOrSolutions.Select(p => $"- `{p.FullPath}`")) +
                    $"\nSet up a [manual build command]({buildCommandDocsUrl}).";
                message.Severity = DiagnosticMessage.TspSeverity.Error;

                AddDiagnostic(message);
            }

            // report any projects that failed to build with MSBuild
            if (msBuildRule is not null && msBuildRule.FailedProjectsOrSolutions.Any())
            {
                var message = MakeDiagnostic("msbuild-build-failure", "Some projects or solutions failed to build using MSBuild");
                message.MarkdownMessage =
                    "CodeQL was unable to build the following projects using MSBuild:\n" +
                    string.Join('\n', msBuildRule.FailedProjectsOrSolutions.Select(p => $"- `{p.FullPath}`")) +
                    $"\nSet up a [manual build command]({buildCommandDocsUrl}).";
                message.Severity = DiagnosticMessage.TspSeverity.Error;

                AddDiagnostic(message);
            }
        }

        /// <summary>
        /// Gets the build strategy that the autobuilder should apply, based on the
        /// options in the `lgtm.yml` file.
        /// </summary>
        private CSharpBuildStrategy GetCSharpBuildStrategy()
        {
            if (Options.BuildCommand is not null)
                return CSharpBuildStrategy.CustomBuildCommand;

            if (Options.Buildless)
                return CSharpBuildStrategy.Buildless;

            if (Options.MsBuildArguments is not null
                || Options.MsBuildConfiguration is not null
                || Options.MsBuildPlatform is not null
                || Options.MsBuildTarget is not null)
            {
                return CSharpBuildStrategy.MSBuild;
            }

            if (Options.DotNetArguments is not null || Options.DotNetVersion is not null)
                return CSharpBuildStrategy.DotNet;

            return CSharpBuildStrategy.Auto;
        }

        private enum CSharpBuildStrategy
        {
            CustomBuildCommand,
            Buildless,
            MSBuild,
            DotNet,
            Auto
        }
    }
}
