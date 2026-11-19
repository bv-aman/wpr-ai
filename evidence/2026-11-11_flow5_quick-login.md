# Flow 5 — Quick login (OxyBoron, live run)

**Date:** 2026-11-11

## Call

`GET /sites/5bb980b19dbd41de9f9b6a2f4f41c2b7/wp/users/sso-login-url`

## Result

✅ Returned a signed, time-limited SSO URL for `https://oxyboron.com` (`wp-load.php?…bvMethod=atolgn&bvTime=…&bvprms=…` — token masked here; full URL captured in the run log). One call, zero changes on the site.

## Notes for the customer pack

- Treat the URL like a password: deliver it directly, never store it in files/logs.
- Staging variant: `GET /staging-sites/{id}/wp/users/sso-login-url`.
- Failure mode to document: site `connection: disconnected` → SSO can't be served (see Flow 2's site for an example).
