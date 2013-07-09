import os, re, mmap
import unittest
import inspect
import bb
from oeqa.utils.sshcontrol import SSHControl


def runTests(tc):

    # set the context object passed from the test class
    setattr(oeRuntimeTest, "tc", tc)

    # prepare test suite, loader and runner
    suite = unittest.TestSuite()
    testloader = unittest.TestLoader()
    testloader.sortTestMethodsUsing = None
    runner = unittest.TextTestRunner(verbosity=2)

    bb.note("Test modules  %s" % tc.testslist)
    suite = testloader.loadTestsFromNames(tc.testslist)
    bb.note("Found %s tests" % suite.countTestCases())

    result = runner.run(suite)

    return result



class oeRuntimeTest(unittest.TestCase):
    testFailures = []
    testSkipped = []
    testErrors = []
    pscmd = "ps"

    def __init__(self, methodName='runTest'):
        self.target = oeRuntimeTest.tc.target
        super(oeRuntimeTest, self).__init__(methodName)


    def run(self, result=None):
        super(oeRuntimeTest, self).run(result)

        # we add to our own lists the results, we use those for decorators
        if len(result.failures) > len(oeRuntimeTest.testFailures):
            oeRuntimeTest.testFailures.append(str(result.failures[-1][0]).split()[0])
        if len(result.skipped) > len(oeRuntimeTest.testSkipped):
            oeRuntimeTest.testSkipped.append(str(result.skipped[-1][0]).split()[0])
        if len(result.errors) > len(oeRuntimeTest.testErrors):
            oeRuntimeTest.testErrors.append(str(result.errors[-1][0]).split()[0])

    @classmethod
    def hasPackage(self, pkg):

        pkgfile = os.path.join(oeRuntimeTest.tc.d.getVar("WORKDIR", True), "installed_pkgs.txt")

        with open(pkgfile) as f:
            data = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            match = re.search(pkg, data)
            data.close()

        if match:
            return True

        return False

    @classmethod
    def hasFeature(self,feature):

        if feature in oeRuntimeTest.tc.d.getVar("IMAGE_FEATURES", True).split() or \
                feature in oeRuntimeTest.tc.d.getVar("DISTRO_FEATURES", True).split():
            return True
        else:
            return False




def getmodule(pos=2):
    # stack returns a list of tuples containg frame information
    # First element of the list the is current frame, caller is 1
    frameinfo = inspect.stack()[pos]
    modname = inspect.getmodulename(frameinfo[1])
    #modname = inspect.getmodule(frameinfo[0]).__name__
    return modname

def skipModule(reason, pos=2):
    modname = getmodule(pos)
    if modname not in oeRuntimeTest.tc.testsrequired:
        raise unittest.SkipTest("%s: %s" % (modname, reason))
    else:
        bb.warn("Test %s is required, not skipping" % modname)

def skipModuleIf(cond, reason):

    if cond:
        skipModule(reason, 3)

def skipModuleUnless(cond, reason):

    if not cond:
        skipModule(reason, 3)
