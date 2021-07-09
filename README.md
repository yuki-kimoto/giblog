<h1>Giblog - Website and Blog builder</h1>

Giblog is <b>Website and Blog builder</b> written by Perl.

You can create <b>your website and blog</b> easily</b>.

All created files is <b>static HTML</b>, so you can manage them using <b>git</b>.

You can <b>customize your website by Perl</b>.

<h2>Website</h2>

<a href="https://new-website-example.giblog.net/">Website</a><br><br>

<a href="https://new-website-example.giblog.net/"><img src="/images/giblog-website.png" style="widht:98%;border:1px solid #ddd"></a><br>

<h2>Blog</h2>

<a href="https://new-blog-example.giblog.net/">Blog Example</a><br><br>

<a href="https://new-blog-example.giblog.net/"><img src="/images/giblog-blog.png" style="widht:98%;border:1px solid #ddd"></a><br><br>

<h2>Usage</h2>

Giblog is command line tool.

<pre>
  # New empty web site
  giblog new mysite

  # New web site
  giblog new_website mysite

  # New blog
  giblog new_blog mysite
  
  # Change directory
  cd mysite
  
  # Add new entry
  giblog add

  # Build web site
  giblog build
  
  # Serve web site
  giblog serve

  # Publish web site
  giblog publish origin main

  # Add new entry with home directory
  giblog add --home /home/kimoto/mysite
  
  # Build web site with home directory
  giblog build --home /home/kimoto/mysite
</pre>

<h2>Features</h2>

Giblog have the following features.

* Build Website and Blog.
* Linux, Mac OS Support. In Windows, need WSL2 or msys2.
* Responsive web site support. Default CSS is setup for PC and Smart phone.
* Header, Hooter and Side bar support
* You can customize Top and Bottom section of content.
* Automatical Line break. p tag is automatically added.
* Escape E<lt>, E<gt> automatically in pre tag
* Title tag is automatically added from first h1-h6 tag.
* Description meta tag is automatically added from first p tag.
* You can customize your web site by Perl programming laugnage.
* You can serve your web site in local environment. Contents changes is detected and build automatically(need L<Mojolicious>).
* Build 645 pages by 0.78 seconds in starndard linux environment.
* All build files is Static. you can manage files by Git.

<h2>Giblog Doument</h2>

If you try Giblog, see the following doucment.

[Giblog Document](https://metacpan.org/pod/Giblog)

<h2>LICENSE AND COPYRIGHT</h2>

Copyright 2018-2019 Yuki Kimoto C<< <kimoto.yuki at gmail.com> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0)
