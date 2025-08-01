mettere il file di configurazione in un posto non standard e lanciare la sessione con --config=/etc/cose/weston.ini
create le chiavi con wayland_keygen.sh
mettere il file /etc/pam.d/weston-remote-access

```
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so

auth            required        pam_securetty.so
auth            include         system-auth
account         required        pam_nologin.so
account         include         system-auth
password        include         system-auth
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so close
session         include         system-auth
session         required        pam_loginuid.so
#session         optional        pam_console.so
#session [success=ok ignore=ignore module_unknown=ignore default=bad] pam_selinux.so open
```

(che sarebbe la copia di system-auth)