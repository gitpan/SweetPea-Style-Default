package SweetPea::Style::Default;
use base 'SweetPea';

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT @EXPORT_OK );
    @ISA    = qw( Exporter );
    @EXPORT = qw(makeapp);
}

use strict;
use constant clear => lc($^O) =~ /(dos)|(mswin)/
  ? sub { system("cls") }
  : sub { system("clear") };

no warnings "all";

use DBIx::Class;
use DBIx::Class::Schema::Loader qw/make_schema_at/;
use Data::FormValidator;
use Email::Stuff;
use Template;

sub makeapp {
    my @dbh = @ARGV;
    @ARGV = ();
    
    my $syntax = 'e.g. perl -MSweetPea::Style::Default -e makeapp dbi:mysql:test root ****';
    
    if (@dbh > 1) {
        SweetPea::makeapp;
        backup('./sweet/application/Model/Schema.pm');
        make_schema_at(
            'Model::Schema',
            { debug => 1, dump_directory => './sweet/application/' },
            [
                @dbh
            ]
        );
        clear->();
        
        print "Building application structure using ...\n";
        print "SweetPea, DBIx::Class, Data::FormValidator and Template-Toolkit\n\n";
        print ". building application structure...\n";
        print ". building database models...\n";
        print ". building authentication files...\n";
        
        #backup('./sweet/application/Controller/Root.pm');
        #SweetPea::makefile(root(), 'sweet/application/Controller/Root.pm');
        #backup('./sweet/application/Controller/Auth.pm');
        #SweetPea::makefile(auth(), 'sweet/application/Controller/Auth.pm');
        backup('./sweet/App.pm');
        SweetPea::makefile(app(), 'sweet/App.pm');
        backup('./sweet/application/View/Main.pm');
        SweetPea::makefile(view_main(), 'sweet/application/View/Main.pm');
        #backup('./sweet/application/View/Grid.pm');
        #SweetPea::makefile(view_grid(), 'sweet/application/View/Grid.pm');
        
        print ". building application scaffolding...\n";
        
        mkdir './sweet/layouts';
        #backup('./sweet/layouts/admin/main.html');
        #SweetPea::makefile(admin_main_layout(), 'sweet/layouts/admin/main.html');
        #backup('./sweet/templates/admin/login.html');
        #SweetPea::makefile(admin_login_template(), 'sweet/templates/admin/login.html');
        #backup('./static/css/style.css');
        #SweetPea::makefile(default_style_css(), 'static/css/style.css');
        
        my $db = 'Model::Schema';
        my $schema = $db->connect(@dbh);
        my $tables = $schema->{source_registrations};
        foreach my $table ( keys %{$tables} ) {
            backup('./sweet/application/Controller/Admin/'.$table.'.pm');
            SweetPea::makefile(ctrl_data($table), 'sweet/application/Controller/Admin/'.$table.'.pm');
        }
        
        print "\n\n";
        print "SweetPea scaffolding complete, courtesy of SweetPea::Style::Default.\n";
    }
    else {
        print "Please supply a proper DBI datasource, e.g. dbi:mysql:dbname\n" . $syntax;
        exit;
    }
}

sub backup {
    my $file = shift;
    my ($path, $file) = $file =~ /(.*[\\\/])?([^\\\/]+\.\w+$)/;
    my $opath = $path;
    my @folders = split /[\\\/]/, $path;
    my $tpath = './backups/';
    mkdir $tpath unless -e -d $tpath;
    
    foreach my $path (@folders) {
        next if $path =~ /^\./;
        $path =~ s/^\.\///;
        unless( -e "$tpath$path" ) {
            mkdir "$tpath$path";
        }
        $tpath = "$tpath$path/"; 
    }
    
    $path = $tpath;
    
    opendir(DIR, $path) || die "Can't opendir $path: $!";
    my $cnt = grep { /$file/ } readdir(DIR);
    closedir DIR;
    
    if (-e "$opath$file") {
        open IN, "<$opath$file";
        my @INDATA = <IN>;
        close IN;
        
        open OUT, ">$path$file.bak.$cnt";
        print OUT "$_" foreach @INDATA;
        close OUT;
        
        print "- created backup $path$file.bak.$cnt\n";
        unlink "$opath$file";
    }
}

# Templates
sub ctrl_data {
    my $controller = shift;
    return <<EOF;
package Controller::Admin::$controller;

=head1 NAME

Controller::Admin::$controller - Controller Description.

=cut

sub _begin {
    my ( \$self, \$s ) = \@_;
}

sub _index {
    my ( \$self, \$s ) = \@_;
    # default action is to forward to view
    \$self->show(\$s);
}

sub _end {
    my ( \$self, \$s ) = \@_;
}

sub create {
    my (\$self, \$s) = \@_;
}

sub update {
    my (\$self, \$s) = \@_;
}

sub show {
    my (\$self, \$s) = \@_;
    \$s->html("I'm inside of controller Controller::Admin::$controller");
}

sub delete {
    my (\$self, \$s) = \@_;
}

1;
EOF
}

sub root {
    return <<'EOF';
package Controller::Root;

=head1 NAME

Controller::Root - Root Controller / Landing Page (Should Exist).

=cut

sub _startup {
    my ( $self, $s ) = @_;
    unless ( $s->session->param('authenticated') ) {
        unless ( $s->controller =~ /^\/auth/ ) {
            $s->redirect('auth');
        }
    }
}

sub _begin {
    my ( $self, $s ) = @_;
}

sub _index {
    my ( $self, $s ) = @_;
    $s->detach('/sweet/welcome');
}

sub _end {
    my ( $self, $s ) = @_;
}

sub _shutdown {
    my ( $self, $s ) = @_;
}

1;
EOF
}

sub auth {
    return <<'EOF';
package Controller::Auth;

=head1 NAME

Controller::Auth - Basic Authentication Template

=cut

=head2 auth

=cut

sub _index {
    my ( $self, $s ) = @_;
    $s->html(
	$s->render({
	    layout   => 'admin/main.html',
	    template => 'admin/login.html'
	})
    );
}

=head2 login

=cut

sub login {
    my ( $self, $s ) = @_;
    my $input = $s->cgi->Vars;
    
    if ($input->{submit}) {
        # validate submitted data
        if ( $input->{user} eq 'admin' && $input->{pass} eq 'pass' ) {
            $s->session->param( authenticated => 1 );
            $s->redirect('admin/dashboard');
        }
        else {
            $s->store->{error} = "Your Login Attempt Was Unsuccessful!";
            $self->_index($s);
        }
    }
    else {
        $s->detach('/auth/_index');
    }
}

1;
EOF
}

sub app {
    return <<'EOF';
package App;

use warnings;
use strict;

use Data::FormValidator;
use View::Main;
use Model::Schema;
use DBIx::Class;
use Template;

=head1 NAME

App - Loads modules and provides accessors to SweetPea.

=cut

sub plugins {
    my $s = pop @_;

    # load modules using the following procedure, they will be available to
    # the application as $s->nameofobject.

    # Note! CGI (cgi), CGI::Cookie (cookie), and CGI::Session (session) 
    # plugins/modules are pre-loaded and available. 

    $s->plug( 'view', sub { shift; return View::Main->new(@_) } );
    $s->plug( 'data', sub { shift; return Model::Schema->new(@_) } );
    $s->plug( 'form', sub { shift; return Data::FormValidator->new(@_) } );
    
    no strict 'refs';
    
    *{"SweetPea::render"} = sub {
        my ( $self, $opts ) = @_;
        $self->view->process(
            "templates/$opts->{template}",
            { s => $self },
            \$opts->{template_data}
        ) if defined $opts->{template};
        $self->view->process(
            "layouts/$opts->{layout}",
            { content => $opts->{template_data}, s => $self },
            \$opts->{layout_data}
        ) if defined $opts->{layout};
        return $opts->{layout_data} if defined $opts->{layout_data};
    };

    return $s;
}

1;    # End of App
EOF
}

sub view_main {
    return <<'EOF';
package View::Main;
use strict;
use warnings;
use Template;

sub new {
    my $config = {
        INCLUDE_PATH => 'sweet/',
        #INTERPOLATE  => 1,
        EVAL_PERL    => 1,
    };

    # create Template object
    return Template->new($config);
}

1;
EOF
}

sub view_grid {
    return <<'EOF';
package View::Grid;
use strict;
use warnings;
use Template;

sub new {
    my ( $class, $self, $options ) = @_;

    my $config = {
        INCLUDE_PATH => 'sweet/templates/components/',
        #INTERPOLATE  => 1,
        EVAL_PERL => 1,
    };

    # create Template object
    my $grid;
    Template->new($config)->process( 'grid.html',
        { o => $options, s => $self }, \$grid );
    return $grid;
}

1;
EOF
}

sub default_style_css {
    return <<'EOF';
html,body,form,h1,h2,h3,h4,h5,h6,p {
margin:0;
padding:0;
}

body {
background:#eceee6;
font-size:.8em;
color:#777;
font-family:Arial, Helvetica, sans-serif;
margin:0 auto;
}

.contentwidth {
width:800px;
margin:0 auto;
}

p,h1,h2,h3,h4,h5,h6 {
font-weight:400;
padding:4px 0;
}

h1 {
font-size:1.8em;
font-weight:700;
}

h2 {
font-size:1.7em;
}

h3 {
font-size:1.5em;
}

h4 {
font-size:1.4em;
}

h5 {
font-size:1.3em;
font-weight:700;
}

h6 {
font-size:1.1em;
font-weight:700;
}

a {
color:#7FCF00;
}

a:hover {
color:#393b32;
}

a img {
border:0;
}

#message {
background-color:#EDFFCF;
border-bottom-color:#CCCCCC;
border-bottom-style:solid;
border-bottom-width:1px;
color:green;
padding-bottom:3px;
padding-left:3px;
padding-right:3px;
padding-top:3px;
text-align:center;
}

#header-container {
background:#EFEFEF none repeat scroll 0 0;
}

#header #logo {
float:left;
width:460px;
}

#header #headertools {
float:left;
width:340px;
text-align:right;
}

#header #headertools p.welcome {
font-size:1.7em;
padding:20px 0 0;
}

#menu UL LI a {
line-height:41px;
text-decoration:none;
color:#fff;
font-weight:700;
font-size:1.2em;
padding:6px 18px 10px;
}

#menu UL LI a:hover {
color:#777;
}

#menu UL LI a.active {
background:#fff;
color:#777;
text-transform:uppercase;
}

#submenu UL LI a {
line-height:41px;
text-decoration:none;
color:#7FCF00;
font-size:.85em;
padding:6px 18px 8px;
}

#submenu UL LI a:hover,#submenu UL LI a.active {
background:#fff;
color:#393632;
}

#menu-container {
background:#fff url(../images/menuBg.jpg) repeat-x;
border-bottom:1px solid #d9dad3;
}

#breadcrumbs p {
line-height:4em;
font-size:.85em;
}

#breadcrumbs a {
text-decoration:none;
}

.content {
background:#fff;
margin-bottom:15px;
padding:15px;
}

#main p {
line-height:1.8em;
}

.borders {
border-color:#CCC #EAEAEA;
border-style:solid;
border-width:1px 2px;
}

#mainCol {
float:left;
width:570px;
}

#sideCol {
float:left;
width:210px;
margin:0 0 0 18px;
}

form .field label {
display:block;
font-weight:700;
}

form .field {
padding:6px 0;
}

form fieldset {
border:medium solid #EFEFEF;
padding:10px;
}

form .textbox-small,form .textbox,form .textbox-large,form .textarea-small,form .textarea,form .textarea-large,select,form .text input {
padding:4px;
}

form .textbox-small {
width:170px;
}

form .text {
padding-bottom:10px;
}

form .textarea-small {
width:250px;
height:100px;
}

form .textarea-large {
width:450px;
height:100px;
}

form .button-bold,form .button-subdued,form .submit input {
font-weight:700;
color:#fff;
padding:4px;
}

#login form .button-bold {
    width: 97%;
}

form .submit input {
margin-top:10px;
}

form .button-bold,form .submit input {
color:#666;
border:1px solid #ccc;
background:#EFEE;
}

form .button-subdued {
border:1px solid #ccc;
background:#ccc;
}

p.success,p.error {
line-height:2em;
color:#fff;
font-weight:700;
margin:8px 0;
padding:0 10px;
}

p.success {
background:#86ca5d;
border:2px solid #5cb327;
}

p.error {
background:#d44937;
border:2px solid #aa2b1a;
}

label.error {
color:#900;
}

.tabledata {
margin-bottom:10px;
}

.tabledata td {
color:#666;
text-align:left;
border-bottom:1px solid #ccc;
padding:5px;
}

.tabledata label {
display:inline;
}

.tabledata input {
border:none;
color:#666;
background-color:#BFF4FF;
padding:3px;
}

.tabledata .shaded {
background:#eee;
}

#login {
width:190px;
background:#fff;
margin:40px auto;
padding:20px;
}

.clearfix:after {
content:".";
display:block;
clear:both;
visibility:hidden;
line-height:0;
height:0;
}

.clearfix {
display:inline-block;
}

* html .clearfix {
height:1%;
}

#header #headertools p,#header #headertools a,p.success a,p.error a {
color:#666;
}

#menu UL,#submenu UL {
margin:0;
padding:2px 0 0;
}

#menu UL LI,#submenu UL LI {
display:inline;
padding:0 1px;
}

#stats {
background-color:#BFF4FF;
margin:10px 0;
padding:5px;
}

#stats .row {
border-bottom-color:#80A7B1;
border-bottom-style:solid;
border-bottom-width:1px;
padding:10px 5px;
}

#stats .row .left,#stats .row .right {
font-size:1.5em;
color:#1CB9E0;
}

#stats .row .right {
float:right;
}

form label,html[xmlns] .clearfix {
display:block;
}

form .textbox,form .text input,form .textarea {
width:350px;
}

form .textbox-large,form .textarea textarea {
width:450px;
}
EOF
}

sub admin_main_layout {
    return <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=us-ascii" />
    <title>Webapp Administration</title>
    <link href="[% s.url('static/css/style.css') %]" rel="stylesheet" type="text/css" media="screen" />
    <script type="text/javascript" src="[% s.url('static/js/jquery-1.3.min.js') %]"></script>
    <script type="text/javascript" src="[% s.url('static/js/general.js') %]"></script>
</head>

<body>
    [% IF s.store.error %]
    <div id="message">
        <span>[% s.store.error %]</span>
    </div>
    [% END %]
    [% content %]
</body>
</html>
EOF
}

sub admin_login_template {
    return <<'EOF';
    
    <div id="login" class="borders">
    <form action="[% s.url('auth/login') %]" method="post">
        <h3>Administration Login</h3>

        <div class="field">
            <label>Username:<br />
            <input class="textbox-small" name="user" type="text" value="admin" /></label>

        </div>

        <div class="field">
            <label>Password:<br />
            <input class="textbox-small" name="pass" type="password" value="pass" /></label>
        </div>

        <div class="field">
            <input value="Login" class="button-bold" type="submit" name="submit" />

        </div>

        <p style="padding-top: 10px; text-align: center;"><a href="#">Forgot Password</a> / <a href="#">Help</a></p>
    </form>
    </div>
    
EOF
}

1;

__END__

=head1 NAME

SweetPea::Style::Default - The great new SweetPea::Style::Default!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

The first experimental custom scaffolding style for SweetPea. Works but
experimental, not sure if SweetPea users even want this.

    ... at the cli (command-line interface)
    perl -MSweetPea::Style::Default -e makeapp

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head1 AUTHOR

Al Newkirk, C<< <al.newkirk at awnstudio.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sweetpea-style-default at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SweetPea-Style-Default>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SweetPea::Style::Default


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SweetPea-Style-Default>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SweetPea-Style-Default>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SweetPea-Style-Default>

=item * Search CPAN

L<http://search.cpan.org/dist/SweetPea-Style-Default/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Al Newkirk.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of SweetPea::Style::Default
