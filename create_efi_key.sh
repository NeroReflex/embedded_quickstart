#!/bin/sh

openssl req -new -x509 -newkey rsa:2048 -subj "/CN=tutorial's platform key/" -keyout PK.key -out PK.crt -days 3650 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=tutorial's key-exchange-key/" -keyout KEK.key -out KEK.crt -days 3650 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=tutorial's kernel-signing key/" -keyout db.key -out db.crt -days 3650 -nodes -sha256

chmod -v 400 *.key

# From now on efitools are needed

# this needs uuid-runtime
echo "Creating a GUID for owner identification"
uuidgen --random > GUID.txt

echo "Preparing PK for installation in EFI"
cert-to-efi-sig-list -g "$(< GUID.txt)" PK.crt PK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -k PK.key -c PK.crt PK PK.esl PK.auth

echo "Preparing KEK for installation in EFI"
cert-to-efi-sig-list -g "$(< GUID.txt)" KEK.crt KEK.esl
sign-efi-sig-list -g "$(< GUID.txt)" -a -k PK.key -c PK.crt KEK KEK.esl KEK.auth

echo "Preparing db for installation in EFI"
cert-to-efi-sig-list -g "$(< GUID.txt)" db.crt db.esl
sign-efi-sig-list -g "$(< GUID.txt)" -a -k KEK.key -c KEK.crt db db.esl db.auth

echo "Prepare dbx for installation in EFI "
# For the dbx, we just restore the old one and sign it with the KEK private key
cp ../empty_sb_keys/old_dbx.esl old_dbx.esl
sign-efi-sig-list -k KEK.key -c KEK.crt dbx old_dbx.esl old_dbx.auth

echo "Creting DER version of our 3 public keys (certificates)"
openssl x509 -outform DER -in PK.crt -out PK.cer
openssl x509 -outform DER -in KEK.crt -out KEK.cer
openssl x509 -outform DER -in db.crt -out db.cer
