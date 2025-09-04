# Security Notice

## What?

This notice explains how vulnerabilities should be reported to ONS. At ONS there are cyber security and information assurance teams, as well as security-conscious people within the programmes, that assess and triage all reported vulnerabilities.

## Reporting a Vulnerability

ONS advocates responsible vulnerability disclosure. If you've found a vulnerability, we would like to know so we can fix it. Please report vulnerabilities through the following channels:

- Send an email to <security@ons.gov.uk>
- Submit a report through [hackerone](https://hackerone.com/52fa7bc0-5356-4c86-9f79-eeb03e1d55cc/embedded_submissions/new)
- Refer to our [vulnerability disclosure policy](https://www.ons.gov.uk/help/vulnerabilitydisclosurepolicy) for more details

When reporting a vulnerability to us, please include:

- the website, page or repository where the vulnerability can be observed
- a brief description of the vulnerability
- details of the steps we need to take to reproduce the vulnerability
- non-destructive exploitation details

If you are able to, please also include:

- the type of vulnerability, for example, the [OWASP](https://owasp.org/about/) category
- screenshots or logs showing the exploitation of the vulnerability

If you are not sure if the vulnerability is genuine and exploitable, or you have found:

- a non-exploitable vulnerability
- something you think could be improved - for example, missing security headers
- [TLS configuration weaknesses](https://www.cloudflare.com/learning/ssl/transport-layer-security-tls/) - for example weak cipher suite support or the presence of TLS1.0 support
Then you can still reach out via email.

## Guidelines for reporting a vulnerability

When you are investigating and reporting the vulnerability on a ONS domain or subdomain, **you must not**:

- break the law
- access unnecessary or excessive amounts of data
- modify data
- use high-intensity invasive or destructive scanning tools to find vulnerabilities
- try a denial of service - for example overwhelming a service on GOV.UK with a high volume of requests
- disrupt ONS's services or systems
- tell other people about the vulnerability you have found until we have disclosed it
- social engineer, phish or physically attack our staff or infrastructure
- demand money to disclose a vulnerability

Only submit reports about exploitable vulnerabilities through HackerOne.

## Bug bounty

Unfortunately, ONS doesn't offer a paid bug bounty programme.

## Code of Conduct

ONS have a contributors code of conduct, which you can find here: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

### Further reading and inspiration about responsible disclosure and SECURITY.md

- <https://www.gov.uk/help/report-vulnerability>
- <https://mojdigital.blog.gov.uk/vulnerability-disclosure-policy/>
- <https://www.ncsc.gov.uk/information/vulnerability-reporting>
- <https://github.com/Trewaters/security-README>
