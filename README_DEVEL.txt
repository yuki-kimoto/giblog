# Development

# Create new website
rm -rf mysite && make && perl -Mblib script/giblog new mysite
rm -rf mysite && make && perl -Mblib script/giblog new_blog mysite_blog
rm -rf mysite && make && perl -Mblib script/giblog new_hp mysite_hp
rm -rf mysite_zemi && make && perl -Mblib script/giblog new_zemi mysite_zemi

# Create new entry
make && perl -Mblib script/giblog add --giblog-dir=mysite

# Build
make && perl -Mblib script/giblog build -I=mysite/lib --giblog-dir=mysite

# Serve
export PERL5LIB=blib/lib morbo mysite/webapp

make && perl -Mblib script/giblog --giblog-dir=mysitezemi build
