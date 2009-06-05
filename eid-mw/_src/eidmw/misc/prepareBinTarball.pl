#!/usr/bin/perl -w

#######################################################################
## This script packs the beid middleware runtime files in a tarball.
## The script has to be ran after:
## qmake eidmw.pro PKG_NAME=beid
## make
#######################################################################

use strict;
use File::Path;
use File::Copy;

#######################################################################
## Preliminary checks if all directories/files are available
#######################################################################

my $QtVerX = 4;
my $QtVerY = 5;
my $QtVerZ = 0;

my $QtVersion 	= "$QtVerX.$QtVerY.$QtVerZ";

#######################################################################
# name of the file containing the maj.min.rev numbers
#######################################################################
my $versionFilename = "../_Builds/beidversions.mak";
my $version_MAJ = -1;
my $version_MID = -1;
my $version_MIN = -1;

open VERSION, "$versionFilename" or die "[Error] Could not open $versionFilename: $!\n";

#######################################################################
## get the package release version nr
#######################################################################
while(<VERSION>)
{
  if(/^\s*REL_(MAJ|MIN|REV)\s*=\s*(\d+)$/)
  {
    $version_MAJ = $2 if($1 eq "MAJ");
    $version_MID = $2 if($1 eq "MIN");
    $version_MIN = $2 if($1 eq "REV");
  }
  last unless ($version_MAJ == -1 || $version_MID == -1 || $version_MIN == -1);
}
close VERSION;

my $version 	= $version_MAJ.".".$version_MID.".".$version_MIN;

print STDOUT "[Info ] Package version (as found in $versionFilename): $version\n";

#######################################################################
## get the machine architecture
#######################################################################
my $architecture     = `uname -m`;
chomp($architecture);

#######################################################################
## get the compiler version
## can be found in $compiler_version[0],$compiler_version[1],$compiler_version[2]
#######################################################################
my @full_compiler_version = split(/ /,`gcc --version`);
my @compiler_version      = split(/\./,$full_compiler_version[2]);
my $compiler		  = "gcc";

#######################################################################
## get the linux distribution version nr
#######################################################################

my @full_distribution;
my $distribution_version;
my $distribution_name;
my $distro;

if (-e "/etc/fedora-release")
{
	@full_distribution    = split(/ /,`cat /etc/fedora-release`);
	$distribution_version = $full_distribution[2];
	$distribution_name    = $full_distribution[0];
	$distro 	      = "fedora";
}
elsif (-e "/etc/SuSE-release")
{
	@full_distribution    = split(/ /,`cat /etc/SuSE-release`);
	$distribution_version = $full_distribution[1];
	$distribution_name    = $full_distribution[0];
	$distro 	      = "suse";
}
elsif (-e "/etc/debian_version")
{
	my $tmp = `cat /etc/debian_version`;
	chomp($tmp);	
	$distribution_name    = "debian-" . $tmp;
	$distribution_version = "etch";
	$distro 	      = "debian";
}
else
{
	print STDERR "[Error] Unsupported distibution. Can not create tar-ball";
	exit (-1);
}

#######################################################################
## in case of debian, check if the version 2.6 is built
#######################################################################
if ( $distro eq "debian" || $distro eq "suse" || $distro eq "fedora" )
{
	my $libbeid_dir="../../beid-2.6/src/eidlib";
	my $libbeid="libbeid.so";
	my @tmp = split(/\n/,`ls $libbeid_dir/$libbeid.*.*.*`);
	my $nrLibs = @tmp;
	if ( $nrLibs==0 )
	{
		print STDERR "[Error] $libbeid_dir/$libbeid.X.Y.Z not found. Please build first\n";
		exit -1;
	}
	if ( $nrLibs>1 )
	{
		print STDERR "[Error] Multiple libraries found for version 2.6. Remove all unnecessary files and rebuild if necessary.\n";
		exit -1;
	}
}

#######################################################################
my $tarfile = "beid-middleware";
$tarfile = $tarfile . "-" . $version;
$tarfile = $tarfile . "-" . lc($distribution_name) . "-" . $distribution_version;
$tarfile = $tarfile . "-" . $architecture;
my $svn_revision = `cat ../svn_revision | tr -d "\r"`;
chomp($svn_revision);
$tarfile = $tarfile . "-" . $svn_revision;
$tarfile = $tarfile . ".tgz";


my @files_Runtime = 	("beidgui"
			,"beiddialogsQTsrv"
			);

my @files_translation =	("eidmw_de.qm"
			,"eidmw_en.qm"
			,"eidmw_fr.qm"
			,"eidmw_nl.qm"
			);

my @files_imageFormats =("libqjpeg.so"
			);

my @files_lib =		("libbeidapplayer.so"
			,"libbeidcardlayer.so"
			,"libbeidcommon.so"
			,"libbeidlib.so"
			,"libbeidpkcs11.so"
			,"libbeiddialogsQT.so"
			,"libbeidlibJava_Wrapper.so"
			,"libsiscardplugin1__ACS__.so"
			);

my @files_doc =		("README"
			);

my @files_license =	("eID-toolkit_licensingtermsconditions.rtf"
			,"eID-toolkit_licensingtermsconditions.txt"
			);

my @files_scripts =	("install.sh"
			,"uninstall.sh"
			);

my @files_pkcs11 =	("beid-pkcs11-register.html"
			,"beid-pkcs11-unregister.html"
			);


my @languages	=	("Dutch"
			,"French"
			,"German"
			);

#######################################################################
## Check if the package is built
## The directories 'bin' and 'lib' should exists
#######################################################################
my $dirToCheck;
my $baseDir;

$baseDir= "..";

$dirToCheck = "$baseDir/bin";

print STDOUT "[Info ] Checking existence of directory $dirToCheck\n";
opendir(SOME_DIR,"$dirToCheck") or die "[Error] Directory '$dirToCheck' does not exist. is the package built?\n";

$dirToCheck = "$baseDir/lib";

print STDOUT "[Info ] Checking existence of directory $dirToCheck\n";
opendir(SOME_DIR,"$dirToCheck") or die "[Error] Directory '$dirToCheck' does not exist. is the package built?\n";

#######################################################################
## Create the necessary directories
#######################################################################
my $dirToCreate;
$baseDir = "../install";

print STDOUT "[Info ] Creating directory $baseDir\n";

opendir (SOME_DIR, $baseDir) or mkpath($baseDir);

$dirToCreate = "$baseDir/install";

if (-d $dirToCreate)
{
	print "[Error] Directory $dirToCreate exists. Please verify and remove before running this script.\n";
	exit(-1);
}
else 
{
	print "[Error] Cannot create directory $dirToCreate.\n" unless mkpath ($dirToCreate); 
}

$dirToCreate = "$baseDir/install/bin";
print STDOUT "[Info ] Creating directory $dirToCreate\n";
mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";

$dirToCreate = "$baseDir/install/lib";
print STDOUT "[Info ] Creating directory $dirToCreate\n";
mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";

$dirToCreate = "$baseDir/install/jar";
print STDOUT "[Info ] Creating directory $dirToCreate\n";
mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";


foreach (@languages)
{
	$dirToCreate = "$baseDir/install/licenses/$_";
	print STDOUT "[Info ] Creating directory $dirToCreate\n";
	mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";
}

if ($distro eq "debian" || $distro eq "suse" || $distro eq "fedora" )
{
	$dirToCreate = "$baseDir/install/beid-2.6";
	print STDOUT "[Info ] Creating directory $dirToCreate\n";
	mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";
	$dirToCreate = "$baseDir/install/thirdparty";
	mkpath ($dirToCreate) or die "[Error] Cannot create directory $dirToCreate.\n";
}

	
#######################################################################
## Copy the files in the target directories
#######################################################################
my $fromDir;
my $toDir;

#######################################################################
## Copy all the binaries
#######################################################################
$baseDir = "../install";
$fromDir = "../bin";
$toDir   = "$baseDir/install/bin";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_Runtime)
{
	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
	system("chmod +x $toDir/$_");
}

#######################################################################
## Copy all jar files
#######################################################################
#$baseDir = "../install";
#$fromDir = "../jar";
#$toDir   = "$baseDir/install/jar";
#
#print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";
#
#foreach (@files_jar)
#{
#	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
#	system("chmod +x $toDir/$_");
#}

#######################################################################
## Copy the pkcs11 HTML files
#######################################################################
$baseDir = "../install";
$fromDir = "../misc/beid";
$toDir   = "$baseDir/install/bin";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_pkcs11)
{
	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
	system("chmod +x $toDir/$_");
}


#######################################################################
## Copy all the translation files
#######################################################################
$baseDir = "../install";
$fromDir = "../bin";
$toDir   = "$baseDir/install/bin";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_translation)
{
	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
}

#######################################################################
## - Copy all the eidlib lib files
## - restore the x-rights
#######################################################################
$baseDir = "../install";
$fromDir = "../lib";
$toDir   = "$baseDir/install/lib";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_lib)
{
	my $fromfile = "$fromDir/$_*";
	my $tofile   = $toDir;
	my $cmd = "cp -d $fromfile $tofile";
	system($cmd);
	system("chmod +x $toDir/$_");
}

#######################################################################
## Copy all doc files
#######################################################################
$baseDir = "../install";
$fromDir = $baseDir;
$toDir   = "$baseDir/install";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_doc)
{
	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
}

#######################################################################
## Copy all license files
#######################################################################
$baseDir = "../install";
$fromDir = "../misc/licenses_files";
$toDir   = "$baseDir/install/licenses";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@languages)
{
	my $language = $_;

	foreach (@files_license)
	{
		copy("$fromDir/$language/$_","$toDir/$language") or die "[Error] Cannot copy file: $_.\n";
	}
}
copy("$fromDir/English/eID-toolkit_licensingtermsconditions.txt","$toDir/") or die "[Error] Cannot copy file.\n";
copy("$fromDir/THIRDPARTY-LICENSES.txt","$toDir/") or die "[Error] Cannot copy file.\n";

#######################################################################
## Copy all script files
#######################################################################
$baseDir = "../install";
$fromDir = $baseDir;
$toDir   = "$baseDir/install";

print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

foreach (@files_scripts)
{
	copy("$fromDir/$_","$toDir/$_") or die "[Error] Cannot copy file: $_.\n";
	system("chmod +x $toDir/$_");
}

#######################################################################
## Copy config file
#######################################################################
$baseDir = "../install";
$fromDir = $baseDir;
$toDir   = "$baseDir/install/bin";

print STDOUT "[Info ] Copying config file from $fromDir to $toDir.\n";
copy("$fromDir/beid.conf.3.5","$toDir") or die "[Error] Cannot copy file: $_.\n";

#######################################################################
## get the beid 2.6 files compiled on this machine
#######################################################################
if ( $distro eq "debian" || $distro eq "suse" || $distro eq "fedora" )
{
	my $fileToCopy;

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/eidlib";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeid.so.2.?.?`;
	chomp($fileToCopy);

	print STDOUT "[Info ] Copying files from $fromDir to $toDir.\n";

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/beidcommon";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidcommon.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/beidcommlib";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidcomm.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/winscarp";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidpcsclite.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/eidlibjni";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidlibjni.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/eidlibjni/eidlib";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/beidlib.jar`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/belpicgui";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidgui.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/newpkcs11/src/pkcs11";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidpkcs11.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/newpkcs11/src/libopensc";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/libbeidlibopensc.so.?.?.?`;
	chomp($fileToCopy);

	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	#######################################################################
	## only on debian install a new version of the beidgui
	#######################################################################
	if ( $distro eq "debian" )
	{
	
		$baseDir = "../install";
		$fromDir = "../../beid-2.6/src/eidviewer";
		$toDir   = "$baseDir/install/beid-2.6";
		$fileToCopy = `ls $fromDir/beidgui`;
		chomp($fileToCopy);

		copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	}

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/eidviewer/certs";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = "$fromDir/beid-cert-belgiumrca.der";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fileToCopy = "$fromDir/beid-cert-government.der";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fileToCopy = "$fromDir/beid-cert-government2004.der";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fileToCopy = "$fromDir/beid-cert-government2005.der";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fromDir = "../misc/certs";
	$fileToCopy = "$fromDir/beid-cert-belgiumrca2.der";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/eidviewer";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = "$fromDir/beidgui_de.mo";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fileToCopy = "$fromDir/beidgui_fr.mo";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
	$fileToCopy = "$fromDir/beidgui_nl.mo";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../../beid-2.6/src/newpkcs11/etc";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = `ls $fromDir/beid-pkcs11-register.html`;
	chomp($fileToCopy);
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$fileToCopy = `ls $fromDir/beid-pkcs11-unregister.html`;
	chomp($fileToCopy);
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$baseDir = "../install";
	$fromDir = "../install";
	$toDir   = "$baseDir/install/beid-2.6";
	$fileToCopy = "$fromDir/beidgui.conf.2.6";
	copy("$fileToCopy","$toDir/") or die "[Error] Cannot copy file: $fileToCopy.\n";
}
#######################################################################
# thirdparty libraries:
# - Qt X.Y.Z
# - qt.conf
# - qt plugins
#######################################################################
if ( $distro eq "debian" || $distro eq "suse" || $distro eq "fedora" )
{
	my $fileToCopy;
	my $QtFileLocation;

	$baseDir = "../install";
	$toDir   = "$baseDir/install/thirdparty";

	#######################################################################
	# qt libraries
	#######################################################################
	#$QtFileLocation = `ldd ../bin/beidgui | grep libQtGui.so`;
	#$QtFileLocation =~ /(\/.+\/libQtGui.so)/;
	##$fileToCopy = $1;
	#$fileToCopy = `ls $1.*.*.[0-9]`;
	#chomp($fileToCopy);
	$QtFileLocation = `../qmake -v`;
	$QtFileLocation =~ /(\/.+\/lib)/;
	$fileToCopy = "$1/libQtGui.so";

	copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$fileToCopy = "$1/libQtCore.so";
	copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file: $fileToCopy.\n";

	$fileToCopy = "$1/../plugins/imageformats/libqjpeg.so";
	copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file: $fileToCopy.\n";

	#$baseDir = "../install";
	#$toDir   = "$baseDir/install/thirdparty";
	#$QtFileLocation = `ldd ../bin/beidgui | grep libQtCore.so`;
	#$QtFileLocation =~ /(\/.+\/libQtCore.so)/;
	##$fileToCopy = $1;
	#$fileToCopy = `ls $1.*.*.[0-9]`;
	#chomp($fileToCopy);
	#copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file: $fileToCopy.\n";

	#######################################################################
	# qt config file
	#######################################################################
	$baseDir = "../install";
	$fromDir = "../install";
	$toDir   = "$baseDir/install/thirdparty";
	$fileToCopy = "$fromDir/qt.conf";
	copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file: $fileToCopy.\n";

	#######################################################################
	# qt plugins
	#######################################################################
	#$QtFileLocation = `ldd ../bin/beidgui | grep libQtGui.so`;
	#$QtFileLocation =~ /(\/.+)\/lib\/libQtGui.so/;
	#$toDir   = "$baseDir/install/thirdparty";
	#my $pathToPlugins;
	#$pathToPlugins = $1 . "/plugins/imageformats";
	#$fileToCopy = "$pathToPlugins/libqjpeg.so";
	#copy("$fileToCopy","$toDir") or die "[Error] Cannot copy file $fileToCopy.\n";
}

#######################################################################
## Copy the desktop file and the icon
#######################################################################
$baseDir = "../install";
$fromDir = $baseDir;
$toDir   = "$baseDir/install";

print STDOUT "[Info ] Copying desktop file from $fromDir to $toDir.\n";
copy("$fromDir/beidgui35.desktop","$toDir") or die "[Error] Cannot copy file: $_.\n";

print STDOUT "[Info ] Copying icon file from $fromDir to $toDir.\n";
copy("$fromDir/eid35.png","$toDir") or die "[Error] Cannot copy file: $_.\n";

#######################################################################
## tar the install directory
#######################################################################
my $cmd;
my $tardir = "../install";

print STDOUT "[Info ] Tar-ing to file $tarfile.\n";

chdir($tardir);
$cmd = "tar czf $tarfile install";
system($cmd);

#######################################################################
## Remove the directory we tarred
#######################################################################
if (-e $tarfile)
{
	print STDOUT "[Info ] Removing tar-ed directories and files.\n";
	$cmd = "rm -r install";
	system($cmd);
}
else
{
	print STDERR "[Error] Can not create $tarfile.\n";
	exit(-1);
}

print STDOUT "[Info ] Tarfile $tarfile created.\n";
print STDOUT "[Info ] Done...\n";

exit(0);

