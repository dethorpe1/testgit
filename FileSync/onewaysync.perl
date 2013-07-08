#!/usr/bin/perl

#
# Replacement for Windows "briefcase"
# Will sync files one way from sync directory
# to "briefcase" directory (hardcoded below)
#

use strict;
use warnings;
use File::Find;
use File::Copy;
use Tk;
use Win32::API;
use Win32::WinError qw( ERROR_NO_MORE_FILES );

# Make sure we see console output
$|=1;

# Get Win32 directory listing functions
my ($find_first_file, $find_nxt_file, $find_close) = import_win32();

# Global variables for "briefcase" and
# the directory to sync it to
# ( TODO: make these into data fields and save as defaults later )
my $brief_dir = "C:\\Briefcase";
my $sync_dir = "O:";

# Make this big enough for directory names
my $chk_wid = 40;

my $mw = MainWindow->new;
$mw->title("Sync Briefcase");

my $frame = $mw->Frame;

$frame
  ->Label( -text=>"Sync from $sync_dir to $brief_dir" )->pack;

# Get list of subdirectories
my @dirs = get_dirs( $brief_dir );

# Keep track of which subdirectories are selected
my %sync;

# Just view needed changes or actually copy
$frame->Checkbutton(
  -text=>"Do the copying",
  -variable=>\my $do_copy,
)->pack;
# Default to checked
$do_copy = 1;

# Create a checkbox for every directory
my $all_dirs = 1;
for my $dir (@dirs) {
  $frame->Checkbutton(
    -anchor=>"w",
    -text=>$dir,
    -width=>$chk_wid,
    -variable=>\$sync{$dir},
    -command => sub { $all_dirs = 0 if $sync{$dir} },
  )->pack;
}

# One checkbox to select all directories
$frame->Checkbutton(
  -anchor=>"w",
  -text=>"All directories",
  -width=>$chk_wid,
  -variable=>\$all_dirs,
)->pack;

$frame
  ->Button( -text=>"Sync",-command=>\&sync_dirs )
  ->pack;

# For status messages
my $msg = $frame
  ->Message( -width => '80c', -textvariable => \my $message )->pack;

$frame->pack;
MainLoop; 

# Get list of directories in a directory
sub get_dirs {
  my $dir = shift;
  chdir $dir or die "Dir $dir: $!";
  return grep -d, glob("*");
}

# Sync a list of directories
sub sync_dirs {

  my @dirs = $all_dirs ? @dirs : grep $sync{$_}, @dirs;
  sync_dir($_) for @dirs;
  dsp_msg( "Done!" );
}

# Sync the files from a remote to a local directory
sub sync_dir {
  my $dir = shift;
  dsp_msg( "Getting file info for $dir" );
  my $lcl_dir = "$brief_dir\\$dir";
  my $rem_dir = "$sync_dir\\$dir";
  my $lcl_stat = dir_list( $lcl_dir );
  my $rem_stat = dir_list( $rem_dir );
  my %seen;
  my (@copy_files, @create_files, @del_files);
  dsp_msg( "Comparing files in $dir" );
  for my $file ( sort keys %$lcl_stat ) {
    my $stat = $lcl_stat->{$file};
    if ( !exists $rem_stat->{$file} ) {
      print "Delete file $file\n";
      push @del_files, $file;
    } elsif ( $stat ne $rem_stat->{$file} ) {
      print "Copy file $file\n";
      push @copy_files, $file;
    }
    $seen{$file}++;
  }
  for my $file ( grep !$seen{$_}, sort keys %$rem_stat ) {
    print "Create file $file\n";
    push @create_files, $file;
  }

  if ($do_copy) {
    dsp_msg( "Synching $dir" );
    chdir $rem_dir or die "Can't cd to $rem_dir: $!";
    chdir $lcl_dir or die "Can't cd to $lcl_dir: $!";
    unlink or warn "Error deleting file $_: $^E"
      for sort @copy_files, @del_files;
    my %sub_dirs;
    for my $file ( sort @copy_files, @create_files ) {
      print "Copying $file\n";
      if ( $file =~ /^(.*)\\/ ) {
        my $sub_dir = $1;
        if ( ! $sub_dirs{$sub_dir} ) {
          #  Create non-existant sub-directories
          # '-d' is on local directory, so speed should be ok,
          # If it's a problem, then we should save directory
          # info from the Win32 API calls and work from that
          # BUG HERE: need to create one directory level at a time
          # if file is more than one level deep.
          if ( ! -d $sub_dir ) {
            mkdir $sub_dir or die "Can't create $sub_dir: $^E";
          }
          $sub_dirs{$sub_dir}++;
        }
      }
      copy( "$rem_dir\\$file", $file ) or warn "Error copying $file: $
+^E";
    }
  
    # Remove empty directories
    # (this is "good enough" for me, I synch files, not
    # neccessarily directory structures)
    finddepth( sub { rmdir }, "." );
  }

}

# Display message in both the message window
# and on the console
sub dsp_msg {
  my $msg_txt = shift;
  print "$msg_txt\n";
  # Wipe out previous message to avoid odd redraw effects
  $message = " " x (3 * length($msg_txt));
  $msg->idletasks;
  $message = $msg_txt;
  $msg->idletasks;
}

# Import Windows Directory Listing functions
sub import_win32 {

  Win32::API::Struct->typedef( 'FILETIME', qw(
    DWORD LowDateTime;
    DWORD HighDateTime;
  ));

  Win32::API::Struct->typedef( 'WIN32_FIND_DATA', qw(
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD dwReserved0;
    DWORD dwReserved1;
    TCHAR tFileName[260];
    TCHAR tAlternateFileName[14];
  ));
  
  my $first_file = Win32::API->new('kernel32', 'FindFirstFile', 'PS', 
+'N');
  if ( !defined($first_file) ) {
    die "Can't import FindFirstFile: $^E";
  }
  my $nxt_file = Win32::API->new('kernel32', 'FindNextFile', 'NS', 'I'
+);
  if ( !defined($nxt_file) ) {
    die "Can't import FindNextFile: $^E";
  }
  my $close_file = Win32::API->new('kernel32', 'FindClose', 'N', 'I');
  if ( !defined($close_file) ) {
    die "Can't import FindClose: $^E";
  }

  return $first_file, $nxt_file;
}

# Get directory listing of files and their
# size and modification times from Windows API
sub dir_list {
  my @dirs = my $top_dir = shift;
  my %filestat;
  my $data = Win32::API::Struct->new( 'WIN32_FIND_DATA' );
  while( my $dir = shift @dirs ) {
    ( my $rel_dir = $dir ) =~ s/^\Q$top_dir\E\\?//;
    $rel_dir .= "\\" if $rel_dir;
    my $h = $find_first_file->Call( "$dir\\*", $data );
    if ( defined($h) and $h > 0 ) {
      DIRLOOP: {
        my $file = $data->{tFileName};
        if ( $file !~ /^\.\.?$/ ) {
          # Check if file is really a directory
          if ( $data->{dwFileAttributes} & 16 ) {
            push @dirs, "$dir\\$file";
          } else {
            $filestat{ $rel_dir . $file } = 
              $data->{ftLastWriteTime}->{HighDateTime} . '-' .
              $data->{ftLastWriteTime}->{LowDateTime} . '-' .
              $data->{nFileSizeHigh} . '-' .
              $data->{nFileSizeLow};
          }
        }
        redo DIRLOOP if $find_nxt_file->Call( $h, $data );
      }
    } else {
      die "Error reading $dir: $^E";
    }

    }
  }
  die "Error reading $top_dir: $^E\n" unless $^E + 0 == ERROR_NO_MORE_
+FILES;
  $find_close->Call( $h ) if defined($h);
  return \%filestat;
}

