# This class helps to select a preferred provider out of a set of
# package dependent possible providers. It evaluates the content of
# two colon separated lists:
#
# * a package-local list of possible providers; this list can contain
#   the special 'none' word
#
# * a distribution global list of preferred providers; this list can
#   contain the special '*' token which will return the first possible
#   provider
#
# Functions:
#   multiprovider_crypto(pkg_providers, d)
#     --> it honors the ${DISTRO_CRYPTOPROVIDERS} global variable and
#         returns a crypto provider
#
#   multiprovider_crypto_depends(provider_var, d)
#     --> returns the dependencies of the crypto provider in the
#         provider_var variable
#
# Example:
#   distribution.conf
#     DISTRO_CRYPTOPROVIDERS = 'gnutls:openssl:*'
#   pkg.bb
#     CRYPTO_PROVIDER ?= "${@multiprovider_crypto('gnutls:openssl:none')}"
#     DEPENDS += "${@multiprovider_crypto_depends('CRYPTO_PROVIDER')}"

def _multiprovider_resolve(d, distro_prefvar, pkg_options, enable_fallback = False):
    tmp  = bb.data.getVar(distro_prefvar, d, True)
    if not tmp and enable_fallback:
        tmp = '*'

    pref = tmp.split(':')
    opt  = pkg_options.split(':')

    for p in pref:
        if p in opt:
            bb.debug(2, "Selecting provider '%s' out of %s options" % (p, opt))
            return p

        if p == '*':
            bb.debug(2, "Selecting package default due to wildcard pref")
            return opt[0]

    if 'none' in opt:
        bb.debug(2, "No matching provider; continuing without any provider")
        return ''

    raise "Could not find provider"

### Crypto stuff

def _multiprovider_crypto_depends(provider):
    if provider in ['openssl','gnutls']:
        dep = provider
    elif provider == 'nss':
        dep = 'libnss'
    elif provider in ['', 'none']:
        dep = ''
    else:
        bb.warn("Unknown cryptoprovider '%s'" % provider)
        dep = ''

    return dep

def multiprovider_crypto(pkg_options, d):
    """Returns the best matching entry from the 'pkg_options' list
    within the global ${DISTRO_CRYPTOPROVIDERS}' list.  Both lists are
    colon separated."""

    return _multiprovider_resolve(d, 'DISTRO_CRYPTOPROVIDERS', pkg_options, True)

def multiprovider_crypto_depends(v, d):
    """Returns the dependencies of the crypto provider in the 'v'
    variable."""
    return _multiprovider_crypto_depends(bb.data.getVar(v, d, True))
