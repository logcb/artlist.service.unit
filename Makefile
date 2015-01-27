default: \
	certificates/artlist.website.secret.key \
	certificates/artlist.website.csr \
	artlist_image/artlist.website.secret.key \
	artlist_image/artlist.website.certificates.pem \

# Make secret key for artlist.website
artlist.website.secret.key:
	openssl genrsa -out artlist.website.secret.key 2048

# Make a copy of the secret key for the artlist image
artlist_image/artlist.website.secret.key: certificates/artlist.website.secret.key
	rm -f artlist_image/artlist.website.secret.key
	cp certificates/artlist.website.secret.key artlist_image/artlist.website.secret.key

# Make certificate signing request for artlist.website
certificates/artlist.website.csr: certificates/artlist.website.secret.key
	openssl req -new -key certificates/artlist.website.secret.key -out certificates/artlist.website.csr -subj "/CN=artlist.website"
	openssl req -noout -text -in certificates/artlist.website.csr

# Download intermediate certificate from Gandi.
certificates/GandiStandardSSLCA.pem:
	curl -O https://www.gandi.net/static/CAs/GandiStandardSSLCA.pem > certificates/GandiStandardSSLCA.pem

# PEM encoded file that includes the artlist.website certificate and the intermediate certificate.
artlist_image/artlist.website.certificates.pem: certificates/artlist.website.crt certificates/GandiStandardSSLCA.pem
	rm -f artlist_image/artlist.website.certificates.pem
	touch artlist_image/artlist.website.certificates.pem
	cat certificates/artlist.website.crt >> artlist_image/artlist.website.certificates.pem
	cat certificates/GandiStandardSSLCA.pem >> artlist_image/artlist.website.certificates.pem
