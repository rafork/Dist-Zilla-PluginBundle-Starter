package Dist::Zilla::Starter;

use strict;
use warnings;

our $VERSION = 'v3.0.2';

1;

=encoding UTF-8

=head1 NAME

Dist::Zilla::Starter - Get started with Dist::Zilla

=head1 DESCRIPTION

This is a tutorial and guide for using L<Dist::Zilla> effectively to manage and
release CPAN distributions with C<[@Starter]> and C<[@Starter::Git]>.

See L<Dist::Zilla::PluginBundle::Starter>
(L<::Git|Dist::Zilla::PluginBundle::Starter::Git>) for the plugin bundle, and
L<Dist::Zilla::MintingProfile::Starter>
(L<::Git|Dist::Zilla::MintingProfile::Starter::Git>) for the minting profile.

=head1 CPAN DISTRIBUTIONS

Before getting into how Dist::Zilla manages CPAN distributions, it's important
to understand what a CPAN distribution is. If you are here, you probably know
that L<CPAN|https://www.cpan.org> is a repository of Perl modules that can
easily be downloaded, installed, and updated. But for all of that to work
smoothly, these modules must be uploaded with certain structure; one can't just
upload a tarball of a GitHub repository and expect the CPAN toolchain to
understand it.

Each tarball uploaded to CPAN is a B<release> of a B<distribution> containing
one or more B<modules>. Modules are declared by the L<package|perlfunc/package>
statement, and loaded from the filesystem by the L<use|perlfunc/use> statement.
Package names don't necessarily need to match the name of the file, but for the
file and package to work together effectively as a module, they should match,
with the namespace separators (C<::>) represented by directory separators in
the filesystem, and the module file itself having the C<.pm> file extension.

These module names are the basis of CPAN's module index, which is maintained by
a system called L<PAUSE|https://pause.perl.org>. When a new release is uploaded
to PAUSE, it discovers all packages declared in the distribution, and
determines whether they are intended to be indexed, whether the uploader
has permissions for each package name, and whether it has a newer version than
any currently indexed module of that name. If so, it indexes them, so that
future attempts to install any of those modules by name will install that
release of that distribution, until such time as a new release successfully
indexes those names. By this method, users are able to easily install and
update the latest version of any module, and CPAN installers are able to
satisfy a distribution's prerequisites on other modules.

After downloading a certain release of a distribution for installation, the
CPAN installer will consult the contents of the distribution itself to do so.
In order to provide infinite flexibility to how distributions can be installed,
a file called F<Makefile.PL> consisting of regular Perl code is run, and is
expected to generate a F<Makefile> that dictates the later steps of building,
testing, and installing. (Note: this is user-side building, a separate task
from the author-side distribution build that will be discussed later.) While
this is traditionally implemented by a module called L<ExtUtils::MakeMaker>, a
slightly different process was conceived using a module called
L<Module::Build> (and later L<Module::Build::Tiny>), in which a F<Build.PL> is
provided which generates a perl script named F<Build> to perform these tasks
instead. While both methods have been extended and improved using different
modules, for Dist::Zilla authors the details of user-side installation are
largely unimportant unless custom configuration or installation tasks are
required. As such, Dist::Zilla generates this install script itself via
InstallTool plugins such as L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> or
L<[ModuleBuildTiny]|Dist::Zilla::Plugin::ModuleBuildTiny>.

In addition to the install script, the other important component of a
well-formed CPAN distribution is the metadata. This was originally contained in
a file called F<META.yml>, which implemented the CPAN meta spec versions 1.0
through 1.4. When L<CPAN meta spec version 2|CPAN::Meta::Spec> was conceived,
it was implemented using a new file called F<META.json> that can coexist with
the legacy format. In either format, this metadata describes aspects of the
distribution as a whole such as name, author(s), prerequisites, repository and
bugtracking resources, and optionally the name and version of each included
package (which if provided will be trusted over PAUSE's own manual scan).
Well-formed metadata is important to both ensuring the modules can be correctly
and painlessly installed, and to provide important ancillary information to
tools such as L<MetaCPAN|https://metacpan.org> when it displays the
distribution. Dist::Zilla generates these files as well via the
L<[MetaYAML]|Dist::Zilla::Plugin::MetaYAML> and
L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON> plugins.

The meat of the CPAN distribution, the code, tests, and documentation, are
generally expected to be in a certain structure. Modules (F<.pm>) and
documentation (F<.pod>) are placed in the F<lib/> directory, with a file path
corresponding to the module name, as they will be ultimately installed. Tests
(F<.t>) are placed in the F<t/> directory, and do not get installed.
Executables to install have no strict convention but are usually put in F<bin/>
or F<script/>. You may see distributions with these important files in other
places, usually because they predate these conventions or for compatibility
with old versions of ExtUtils::MakeMaker that required F<.xs> files to be in
the distribution root. Other directories may be included in the CPAN
distribution, but have no specific meaning by default to the standard
installers.

=head1 A BRIEF HISTORY OF AUTHORING

Originally, the same tool which allows end users to install the distribution
could also be used by the author to manage it and create a release.
L<ExtUtils::MakeMaker> contains author-side configuration and commands such as
C<make manifest> and C<make dist>. Indeed, many authors still use this as their
primary authoring tool, though its close-to-metal nature and extreme backcompat
requirement has led many to develop more author-friendly wrappers.

One such wrapper is L<Module::Install>. This differed from many attempts in
that it was designed to bundle itself with the distribution, so the end user
would install using the bundled code rather than relying on the interface of
their possibly outdated ExtUtils::MakeMaker. This was a revolutionary idea and
the wrapper interface was well liked, but it introduced other problems. Due to
being bundled with the release, it too became outdated when the author did not
regularly release new versions of the distribution, so bugs would linger
forever that the end user could not workaround by updating their own toolchain.
This was notably a significant issue when Perl 5.26 stopped loading modules
from the current working directory by default, a mechanism which the
Module::Install code bundled with hundreds of distributions relied upon to load
itself. Additionally, it had a rudimentary plugin system but no way to formally
declare what plugins a distribution was using, meaning that given a
Module::Install-based Makefile.PL, the author or contributor would have to
guess what plugins needed to be installed or bundled for the end user to make
it work. On top of (or perhaps due to) these problems, it has become mostly
unmaintained and thus has fallen far behind the progress of the CPAN toolchain.

L<Module::Build> was created to provide a C<make>-free alternative to
L<ExtUtils::MakeMaker>, with the additional goal of being more modern and
easier to customize and add features to. Unfortunately this proved to be a
lofty goal, as due to widespread use it succumbed to the same stagnation as
ExtUtils::MakeMaker; it too has become extremely complex and obtuse, is no
longer driven to evolve by its primary author, and must maintain backcompat
religiously. This has weakened most of its benefits considerably, as
ExtUtils::MakeMaker still remains more compatible with ancient end-user Perls,
but Module::Build is still used by some who prefer its interface over
ExtUtils::MakeMaker, or who have complicated compilation requirements that are
easier to customize in Module::Build.

More recently, L<Module::Build::Tiny> was created as an extremely simple
implementation of the F<Build.PL> spec pioneered by Module::Build. A
significant reason for its simplicity is that unlike the previously mentioned
tools, it is B<only> an install tool; it does not provide any authoring
features. A separate tool called L<mbtiny> provides these features in a minimal
package, or it works great with dedicated authoring tools like Dist::Zilla.

Dist::Zilla came to be one of the first widespread author-side-only tools, and
as such it shed many of the limitations of its overworked predecessors. It does
not have to concern itself with minimalism and compatibility, because the end
user does not need to install it; it can use everything that modern CPAN has to
offer, and rely on the generated install file to be lightweight and compatible
if needed. The generated install file also has a simpler job, as it doesn't
need to generate the distribution's metadata aside from any dynamic
prerequisites, or implement any author-side commands for convenience, as
Dist::Zilla does these tasks itself. Learning from the mistakes of
Module::Install, it has a formal plugin configuration system, and can
deterministically find what plugins are needed to build the distribution, using
the C<dzil authordeps> command.

=head1 DIST::ZILLA AND BUNDLES

Dist::Zilla is a CPAN distribution authoring framework. At its core, it only
organizes tasks; it requires plugins to implement the specifics of building,
testing, and releasing the distribution. The author can manually specify in
F<dist.ini> the set of plugins that suits their needs, or even write new
plugins, but there are also ready-made tools built upon it that require very
little study to use effectively.

The most basic of these is the core bundle
L<[@Basic]|Dist::Zilla::PluginBundle::Basic>. This bundle contains plugins to
perform the most common authoring tasks, and is used throughout most tutorials
including L<dzil.org|http://dzil.org>, but it has unfortunately become outdated
in practice and, as of this writing, cannot be fixed without breaking changes.

The L<prolific creator|https://metacpan.org/author/MIYAGAWA> of L<cpanm>,
L<Carton>, L<cpanfile>, and other wonderful convenience tools created a
"convention over configuration" tool called L<Dist::Milla>. Dist::Milla is a
bundle, minting profile, and command-line wrapper of Dist::Zilla which provides
a complete opinionated authoring tool. It requires a certain modernized
structure, and in return removes all of the guesswork in managing and releasing
distributions. Its sister project L<Minilla> is also notable for being able to
achieve almost the same tasks without a dependency on Dist::Zilla, though as a
result it cannot be extended with arbitrary plugins from the Dist::Zilla
ecosystem.

The L<[@Starter]|Dist::Zilla::PluginBundle::Starter> bundle and minting profile
is a middle ground. The intention is to provide an unopinionated tool which can
be used effectively in almost any distribution similarly to C<[@Basic]>, but
that can be updated at the author's request to newer conventions, and can also
optionally provide further modern convenience with slightly stricter and more
opinionated structural requirements. The
L<[@Starter::Git]|Dist::Zilla::PluginBundle::Starter::Git> bundle and minting
profile are variants that provide some extra functionality for a git-based
workflow.

=head1 THE DIST::ZILLA CORE

Dist::Zilla relies almost entirely on its plugin and command system to provide
specific functionality, but these are tied together by a few core systems.

The L<Dist::Zilla> object itself is at the basis of the whole operation. It
contains the basic properties of the distribution, such as name, version, and
the whole set of plugins that will be run. But it doesn't do anything itself;
it is up to other parts of the system to utilize this information.

The L<Dist::Zilla::Dist::Builder> object is a subclass of the main Dist::Zilla
object that additionally is able to B<build> the distribution by executing all
of the relevant plugins. Additionally it can execute the appropriate plugins to
test, install, and release the distribution. It does this primarily by
executing L</PHASES> in a certain order for each task.

The L<Dist::Zilla::Dist::Minter> object is another subclass of the main
Dist::Zilla object, this time to implement the L</MINTING> of new distributions
using minting profiles. It is much simpler as it only does one thing: run all
of the plugins in the minting profile, and write out the resulting build to the
filesystem. It also utilizes a few L</PHASES> to order the execution of
plugins.

L<Dist::Zilla::MVP::Assember> is a L<Config::MVP>-based configuration parser
that is the core of how Dist::Zilla's plugin L</CONFIGURATION> works. It reads
a F<dist.ini> (or F<profile.ini>) and constructs the requested set of plugins
and configuration, and stores them in the Dist::Zilla object.

L<Dist::Zilla::App> is an L<App::Cmd>-based command system that allows the
L<dzil> script to load and execute any installed commands in the
C<Dist::Zilla::App::Command> namespace, such as
L<< C<dzil test>|Dist::Zilla::App::Command::test >> or
L<< C<dzil regenerate>|Dist::Zilla::App::Command::regenerate >>.

L<Test::DZil> is a framework that facilitates testing of Dist::Zilla builds and
minting profiles. It contains constructors for test-appropriate subclasses of
Dist::Zilla::Dist::Builder and Dist::Zilla::Dist::Minter, as well as for
generating simple F<dist.ini> text. This is primarily useful for plugin bundle
and minting profile authors, so is out of scope for this document.

=head1 CONFIGURATION

The Dist::Zilla configuration for a distribution is a standard INI-format file
called F<dist.ini> in the root of the distribution. The "main section", meaning
any configuration before the first category, configures the distribution as a
whole, with directives such as C<name> and C<version>. Each following section
both adds a plugin to be used, and allows configuration to be passed to that
plugin.

  name = Acme-Dist-Name
  [MyPlugin]
  configuration = for MyPlugin

There are a few conventions in section names that Dist::Zilla recognizes in
order to determine how plugins are loaded. The standard section name will
simply be appended to C<Dist::Zilla::Plugin::> to form the class name of the
plugin to load. If the section name ends in C</> followed by other text, that
will be the alias for that instance of the plugin; otherwise, the alias is the
same as the section name. This is important because each section in an INI file
is unique, and because plugins are looked up by this name, so to include the
same plugin twice, at least one of them must have an alias. Additionally, some
plugins use the alias to set configuration, but this a bit overly magical.

  [MyPlugin / FirstPlugin]
  [MyPlugin / SecondPlugin]

If the section name is prefixed with C<@>, this indicates a plugin bundle,
which is prepended with C<Dist::Zilla::PluginBundle::> to be loaded. A plugin
bundle is essentially just a plugin that can only load other plugins, rather
than taking action in any build phases.

  [@MyBundle]
  configuration = for the bundle

Plugins loaded by the bundle will be given an alias in the form
C<@BundleName/PluginName> and so will not conflict if the same plugin is loaded
elsewhere.

A similar convention with the prefix of C<-> indicates a role to be prefixed
with C<Dist::Zilla::Role::>, but these are not configured directly in
F<dist.ini>; roles implement both general interfaces of Dist::Zilla as well as
the L</PHASES> in which plugins take action.

If the section name is prefixed with C<=>, the section name is used as the
plugin class name directly, without prepending C<Dist::Zilla::Plugin::>.

  [=Full::Plugin::Class::Name]

The configuration for each section is generally passed directly to that plugin
or bundle to handle however it wishes, but a special configuration key
C<:version> is recognized in each section by Dist::Zilla itself. In the main
section, it will require at least that version of Dist::Zilla to build the
distribution; in a plugin or bundle section, it will require at least that
version of the plugin or bundle.

  :version = 6.0
  [MyPlugin]
  :version = 0.005

Of additional note is that the C<[@Starter]> bundles (as well as L<Dist::Milla>)
compose the
L<-PluginBundle::PluginRemover|https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::PluginRemover>
and
L<-PluginBundle::Config::Slicer|https://metacpan.org/pod/Dist::Zilla::Role::PluginBundle::Config::Slicer>
roles, which allow plugins within a bundle to be configured directly in
F<dist.ini>. The PluginRemover role recognizes the C<-remove> option and omits
those plugins by name, and the Config::Slicer role recognizes options in the
form of C<PluginName.option> and passes through that option to the named
plugin within the bundle. This prevents having to add manual pass-through code
to the bundle for every possible option that the included plugins accept. But
there is an oddity with options that can be specified multiple times, as
Config::Slicer does not know in advance which options allow this. See
L<Config::MVP::Slicer/"CONFIGURATION SYNTAX"> for full details on config
slicing.

  [@Starter]
  regular = configuration
  -remove = Test::Compile
  GatherDir.exclude_filename[a] = foo
  GatherDir.exclude_filename[b] = bar

Occasionally you may need to specify an authordep (module required for using
the F<dist.ini> itself) that is not explicitly listed as a plugin. For this
purpose, authordeps can additionally be specified as comments.

  ; authordep Pod::Weaver::PluginBundle::DAGOLDEN

=head1 COMMANDS

After setting up the configuration, Dist::Zilla operations are executed by
running commands. Dist::Zilla has a pluggable command system with many core
commands and many more available from CPAN. There are only a few needed for the
basic operation of creating and releasing a distribution. Most commands operate
by executing one or more L</PHASES>.

One of the most common commands is
L<< C<dzil test>|Dist::Zilla::App::Command::test >>. This will build the
distribution in a temporary directory, and then run the configure, build, and
test phases of the L<CPAN::Meta::Spec/Phases>. It will also execute any other
C<-TestRunner> phase plugins such as
L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests>, which runs any
author-side tests from the C<xt/> directory. The C<--release> option can be
passed to run release tests in addition to standard and author tests.

The second most important command is
L<< C<dzil release>|Dist::Zilla::App::Command::release >>. This will build the
distribution, and then upload the archive to PAUSE. The C<--trial> option will
mark the upload as a trial release, so it will not be indexed as stable.

Two commands that are important when starting work on a Dist::Zilla
distribution for the first time are
L<< C<dzil authordeps>|Dist::Zilla::App::Command::authordeps >> and
L<< C<dzil listdeps>|Dist::Zilla::App::Command::listdeps >>. C<authordeps>
lists the Dist::Zilla plugins required by the F<dist.ini>, and C<listdeps>
lists the dependencies of the distribution itself. The output of each can be
piped into L<cpanm> to install any modules needed for working on the
distribution. Note that the C<authordeps> requirements must be installed for
most other C<dzil> commands to succeed, including C<listdeps>. The non-core
command L<< C<dzil installdeps>|Dist::Zilla::App::Command::installdeps >> wraps
this process into a single command.

Some other core commands for distribution management are
L<< C<dzil build>|Dist::Zilla::App::Command::build >>, which builds the
distribution and stores the tarball and extracted directory locally;
L<< C<dzil run>|Dist::Zilla::App::Command::run >>, which builds the
distribution temporarily like C<dzil test> but runs the supplied command
instead; L<< C<dzil install>|Dist::Zilla::App::Command::install >>, which
builds the distribution temporarily and then installs it with a CPAN installer;
and L<< C<dzil clean>|Dist::Zilla::App::Command::clean >> which cleans up the
Dist::Zilla F<.build> directory and any built distribution directories or
archives.

Another common task is to copy updated versions of generated files from the
distribution build to the source tree, such as generated F<README> files.
Often this is done whenever the distribution is built with
L<[CopyFilesFromBuild]|Dist::Zilla::Plugin::CopyFilesFromBuild>, but this can
be disruptive when trying to run tests or other operations. By using the
L<regenerate|Dist::Zilla::PluginBundle::Starter/regenerate> option for
C<[@Starter]>, or the L<[Regenerate]|Dist::Zilla::Plugin::Regenerate> or
L<[Regenerate::AfterReleasers]|Dist::Zilla::Plugin::Regenerate::AfterReleasers>
plugins, the L<< C<dzil regenerate>|Dist::Zilla::App::Command::regenerate >>
command can be used for this purpose instead, so the distribution can be built
without modifying the source tree, and the files can be regenerated as needed.

=head1 MINTING

Dist::Zilla is primarily a distribution management tool, but it leverages the
same command and plugin system to provide a minting tool. A minting profile
can be configured to automatically set up the basic framework for new
distributions. The L<Starter|Dist::Zilla::MintingProfile::Starter> and
L<Starter::Git|Dist::Zilla::MintingProfile::Starter::Git> minting profiles
provide a starting point and instructions for customizing profiles, as does
L<dzil.org|http://dzil.org/tutorial/minting-profile.html>.

Some metadata such as author, license, and copyright needs to be configured to
be set up properly in minted distributions. This configuration is stored in
C<~/.dzil/config.ini>, which can be initialized using the
L<< C<dzil setup>|Dist::Zilla::App::Command::setup >> command.

The process of minting a distribution primarily involves the
L<< C<dzil new>|Dist::Zilla::App::Command::new >> command, invoked with the
name of the module or distribution to create. By default, the local profile in
C<~/.dzil/profiles/default> will be used if present, and otherwise a default
C<[@Basic]> profile. The C<-p> option can be used to specify the profile name
to use, and the C<-P> option can specify an installed minting profile as the
provider. The default profile or provider can be set in the
C<~/.dzil/config.ini> configuration as documented for C<dzil new>.

=head1 PHASES

Plugins included in F<dist.ini> are ordered, but they do not necessarily
execute in order. A Dist::Zilla command such as
L<< C<dzil test>|Dist::Zilla::App::Command::test >> will run one or more
B<phases>, which will execute any code that plugins have registered for that
phase, in the order those plugins were used. The command
L<< C<dzil dumpphases>|Dist::Zilla::App::Command::dumpphases >> can be used to
see a full listing of the phases that the plugins in a F<dist.ini> will run in.

=head2 BeforeBuild

The distribution build consists of several phases, starting with
L<-BeforeBuild|Dist::Zilla::Role::BeforeBuild>, for any build preparation. No
plugins in C<[@Starter]> execute during this phase by default.

=head2 BeforeMint

The L<-BeforeMint|Dist::Zilla::Role::BeforeMint> phase is executed at the
beginning of the minting process for a new distribution source tree instead of
C<-BeforeBuild>.

=head2 FileGatherer

In the L<-FileGatherer|Dist::Zilla::Role::FileGatherer> phase, many plugins add
files to the distribution; in C<[@Starter]> this includes the plugins
L<[GatherDir]|Dist::Zilla::Plugin::GatherDir>,
L<[MetaYAML]|Dist::Zilla::Plugin::MetaYAML>, 
L<[MetaJSON]|Dist::Zilla::Plugin::MetaJSON>,
L<[License]|Dist::Zilla::Plugin::License>,
L<[Pod2Readme]|Dist::Zilla::Plugin::Pod2Readme>,
L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>,
L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>,
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>,
L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> (or the configured installer
plugin), and L<[Manifest]|Dist::Zilla::Plugin::Manifest>. This phase is also
executed by the minting process to add files to a new distribution source tree.

=head2 EncodingProvider

In the L<-EncodingProvider|Dist::Zilla::Role::EncodingProvider> phase, a plugin
may set the encoding for gathered files. No plugins in C<[@Starter]> execute
during this phase by default. This phase is also executed by the minting
process.

=head2 FilePruner

In the L<-FilePruner|Dist::Zilla::Role::FilePruner> phase, gathered files may
be removed from the distribution. In C<[@Starter]> this is handled by the
plugins L<[PruneCruft]|Dist::Zilla::Plugin::PruneCruft> and
L<[ManifestSkip]|Dist::Zilla::Plugin::ManifestSkip>. This phase is also
executed by the minting process.

=head2 FileMunger

In the L<-FileMunger|Dist::Zilla::Role::FileMunger> phase, files in the
distribution may be modified. In C<[@Starter]> the plugin
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile> runs during this phase
in order to update its test file to test all gathered modules and scripts. With
the L<managed_versions|Dist::Zilla::PluginBundle::Stater/managed_versions>
option, the L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> and
L<[NextRelease]|Dist::Zilla::Plugin::NextRelease> plugins also operate during
this phase. This phase is also executed by the minting process.

=head2 AfterMint

The L<-AfterMint|Dist::Zilla::Role::AfterMint> phase is executed to conclude
the minting process for a new distribution source tree. The build process
instead continues with several more phases.

=head2 PrereqSource

In the L<-PrereqSource|Dist::Zilla::Role::PrereqSource> phase, plugins can add
prerequisites to the distribution. In C<[@Starter]> the plugins
L<[PodSyntaxTests]|Dist::Zilla::Plugin::PodSyntaxTests>,
L<[Test::ReportPrereqs]|Dist::Zilla::Plugin::Test::ReportPrereqs>,
L<[Test::Compile]|Dist::Zilla::Plugin::Test::Compile>, and
L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> (or the configured installer
plugin) add prereqs during this phase. Plugins used to configure the
distribution's prereqs such as L<[Prereqs]|Dist::Zilla::Plugin::Prereqs>,
L<[Prereqs::FromCPANfile]|Dist::Zilla::Plugin::Prereqs::FromCPANfile>, and
L<[AutoPrereqs]|Dist::Zilla::Plugin::AutoPrereqs> will normally run in this
phase.

=head2 InstallTool

In the L<-InstallTool|Dist::Zilla::Role::InstallTool> phase, the installer's
F<Makefile.PL> or F<Build.PL> is generated in the distribution. In
C<[@Starter]>, L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> or the configured
installer plugin handles this phase.

=head2 AfterBuild

The L<-AfterBuild|Dist::Zilla::Role::AfterBuild> phase concludes the
distribution build, for any post-build cleanup. No plugins in C<[@Starter]>
execute during this phase by default.

=head2 BuildRunner

The L<-BuildRunner|Dist::Zilla::Role::BuildRunner> phase executes the configure
and build phases of the L<CPAN::Meta::Spec/Phases> (not to be confused with the
Dist::Zilla build that creates the distribution). This is primarily used to
prepare the distribution for testing or installing. In C<[@Starter]>,
L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> or the configured installer
plugin handles this phase.

=head2 TestRunner

The L<-TestRunner|Dist::Zilla::Role::TestRunner> phase executes the test phase
of the L<CPAN::Meta::Spec/Phases> and runs any author-side testing. In
C<[@Starter]>, L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker> (or the configured
installer plugin) and L<[RunExtraTests]|Dist::Zilla::Plugin::RunExtraTests>
handle this phase.

=head2 BeforeArchive

The L<-BeforeArchive|Dist::Zilla::Role::BeforeArchive> phase is executed after
building the distribution and before packaging it into an archive, such as for
the L<< C<dzil build>|Dist::Zilla::App::Command::build >> command or before
releasing. No plugins in C<[@Starter]> execute during this phase by default.

=head2 BeforeRelease

The L<-BeforeRelease|Dist::Zilla::Role::BeforeRelease> phase prepares a built
distribution for release. In C<[@Starter]>, the plugins
L<[TestRelease]|Dist::Zilla::Plugin::TestRelease>,
L<[ConfirmRelease]|Dist::Zilla::Plugin::ConfirmRelease>, and
L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN> (to ensure PAUSE username
and password are available) execute during this phase. In C<[@Starter::Git]>,
the plugin L<[Git::Check]|Dist::Zilla::Plugin::Git::Check> executes during this
phase. Other pre-release checks like
L<[CheckChangesHasContent]|Dist::Zilla::Plugin::CheckChangesHasContent> also
execute in this phase.

=head2 Releaser

The L<-Releaser|Dist::Zilla::Role::Releaser> phase releases the distribution to
CPAN. In C<[@Starter]>, L<[UploadToCPAN]|Dist::Zilla::Plugin::UploadToCPAN> (or
L<[FakeRelease]|Dist::Zilla::Plugin::FakeRelease>) handles this phase.

=head2 AfterRelease

The L<-AfterRelease|Dist::Zilla::Role::AfterRelease> phase concludes the
distribution release process, performing any post-release cleanup or tagging.
No plugins in C<[@Starter]> execute during this phase by default. With the
L<managed_versions|Dist::Zilla::PluginBundle::Stater/managed_versions> option,
the L<[NextRelease]|Dist::Zilla::Plugin::NextRelease> and
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
plugins execute during this phase. With the
L<regenerate|Dist::Zilla::PluginBundle::Starter/regenerate> option, the
L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease> plugin
executes during this phase. In C<[@Starter::Git]>, the plugins
L<[Git::Commit]|Dist::Zilla::Plugin::Git::Commit>,
L<[Git::Tag]|Dist::Zilla::Plugin::Git::Tag>, and
L<[Git::Push]|Dist::Zilla::Plugin::Git::Push> execute during this phase.

=head2 NameProvider

The L<-NameProvider|Dist::Zilla::Role::NameProvider> phase executes when
required rather than at a specific time, to determine the name of the
distribution. No plugins in C<[@Starter]> execute during this phase by default,
and the name can be provided directly by setting C<name> in F<dist.ini>. The
L<[NameFromDirectory]|Dist::Zilla::Plugin::NameFromDirectory> plugin can act as
a name provider.

=head2 VersionProvider

The L<-VersionProvider|Dist::Zilla::Role::VersionProvider> phase executes when
required rather than at a specific time, to determine the version of the
distribution. No plugins in C<[@Starter]> execute during this phase by default,
and the version can be provided directly by setting C<version> in F<dist.ini>.
With the
L<managed_versions|Dist::Zilla::PluginBundle::Starter/managed_versions> option,
the L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion> plugin acts as the
version provider.

=head2 ReleaseStatusProvider

The L<-ReleaseStatusProvider|Dist::Zilla::Role::ReleaseStatusProvider> phase
executes when required rather than at a specific time, to determine the
L<CPAN::Meta::Spec/release_status> of the distribution. No plugins in
C<[@Starter]> execute during this phase by default. It defaults to C<stable>
and is usually set to another value by passing the C<--trial> option to
L<< C<dzil release>|Dist::Zilla::App::Command::release >> or using a version
containing an underscore, but can also be set by a plugin in this phase.

=head2 LicenseProvider

The L<-LicenseProvider|Dist::Zilla::Role::LicenseProvider> phase executes when
required rather than at a specific time, to determine the license of the
distribution. No plugins in C<[@Starter]> execute during this phase by default,
and the license can be provided directly by setting C<license> in F<dist.ini>,
or otherwise guessed from the main module's POD.

=head2 MetaProvider

The L<-MetaProvider|Dist::Zilla::Role::MetaProvider> phase executes when
required rather than at a specific time, to generate the distribution's
L<CPAN metadata|CPAN::Meta::Spec>. In C<[@Starter]>, the
L<[MetaConfig]|Dist::Zilla::Plugin::MetaConfig>,
L<[MetaProvides::Package]|Dist::Zilla::Plugin::MetaProvides::Package>, and
L<[MetaNoIndex]|Dist::Zilla::Plugin::MetaNoIndex]> plugins provide metadata in
this phase. Other metadata providers like
L<[MetaResources]|Dist::Zilla::Plugin::MetaResources> also execute in this
phase.

=head2 ShareDir

The L<-ShareDir|Dist::Zilla::Role::ShareDir> phase executes when required
rather than at a specific time, to configure sharedirs for installation. In
C<[@Starter]>, the L<[ShareDir]|Dist::Zilla::Plugin::ShareDir> plugin
configures a distribution sharedir if present.

=head2 ExecFiles

The L<-ExecFiles|Dist::Zilla::Role::ExecFiles> phase executes when required
rather than at a specific time, to configure files for installation as
executables. In C<[@Starter]>, the L<[ExecDir]|Dist::Zilla::Plugin::ExecDir>
plugin marks a directory as containing executables, which may be used by
installer plugins such as L<[MakeMaker]|Dist::Zilla::Plugin::MakeMaker>.

=head2 Regenerator

The L<-Regenerator|Dist::Zilla::Role::Regenerator> phase is a non-core
extension which executes when
L<< C<dzil regenerate>|Dist::Zilla::App::Command::regenerate >> is run,
intended for generating files in the source tree outside of a standard
distribution build. With the
L<regenerate|Dist::Zilla::PluginBundle::Starter/regenerate> option for
C<[@Starter]>, the
L<[Regenerate::AfterReleasers]|Dist::Zilla::Plugin::Regenerate::AfterReleasers>
plugin promotes
L<[CopyFilesFromRelease]|Dist::Zilla::Plugin::CopyFilesFromRelease> to also
execute during this phase.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Starter>,
L<Dist::Zilla::PluginBundle::Starter::Git>,
L<Dist::Zilla::MintingProfile::Starter>,
L<Dist::Zilla::MintingProfile::Starter::Git>
