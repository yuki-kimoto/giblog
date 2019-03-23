# Development

# Help
rm -rf mysite && make && perl -Mblib script/giblog
rm -rf mysite && make && perl -Mblib script/giblog -h
rm -rf mysite && make && perl -Mblib script/giblog --help


# Create new website
rm -rf mysite && make && perl -Mblib script/giblog new mysite
rm -rf mysite_blog && make && perl -Mblib script/giblog new_blog mysite_blog
rm -rf mysite_hp && make && perl -Mblib script/giblog new_website mysite_hp

# Create new entry
make && perl -Mblib script/giblog add --home=mysite

# Build
make && perl -Mblib script/giblog build -I=mysite/lib -H=mysite

# Serve
export PERL5LIB=blib/lib morbo mysite/webapp
