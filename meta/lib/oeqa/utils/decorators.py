# Copyright (C) 2013 Intel Corporation
#
# Released under the MIT license (see COPYING.MIT)

# Some custom decorators that can be used by unittests
# Most useful is skipUnlessPassed which can be used for
# creating dependecies between two test methods.

from oeqa.oetest import *
import logging
import sys

class skipIfFailure(object):

    def __init__(self,testcase):
        self.testcase = testcase

    def __call__(self,f):
        def wrapped_f(*args):
            if self.testcase in (oeTest.testFailures or oeTest.testErrors):
                raise unittest.SkipTest("Testcase dependency not met: %s" % self.testcase)
            return f(*args)
        wrapped_f.__name__ = f.__name__
        return wrapped_f

class skipIfSkipped(object):

    def __init__(self,testcase):
        self.testcase = testcase

    def __call__(self,f):
        def wrapped_f(*args):
            if self.testcase in oeTest.testSkipped:
                raise unittest.SkipTest("Testcase dependency not met: %s" % self.testcase)
            return f(*args)
        wrapped_f.__name__ = f.__name__
        return wrapped_f

class skipUnlessPassed(object):

    def __init__(self,testcase):
        self.testcase = testcase

    def __call__(self,f):
        def wrapped_f(*args):
            if self.testcase in oeTest.testSkipped or \
                    self.testcase in  oeTest.testFailures or \
                    self.testcase in oeTest.testErrors:
                raise unittest.SkipTest("Testcase dependency not met: %s" % self.testcase)
            return f(*args)
        wrapped_f.__name__ = f.__name__
        return wrapped_f

class testcase(object):

    def __init__(self, test_case):
        self.test_case = test_case

    def __call__(self, func):
	def wrapped_f(*args):
		return func(*args)
	wrapped_f.test_case = self.test_case
	return wrapped_f

def LogResults(original_class):
    orig_method = original_class.run

    #rewrite the run method of unittest.TestCase to add testcase logging
    def run(self, result, *args, **kws):
        orig_method(self, result, *args, **kws)
	passed = True
	testMethod = getattr(self, self._testMethodName)

	#if test case is decorated then use it's number, else use it's name
	try:
		test_case = testMethod.test_case
	except AttributeError:
		test_case = self._testMethodName

	#create custom logging level for filtering.
	custom_log_level = 100
	logging.addLevelName(custom_log_level, 'RESULTS')
	caller = os.path.basename(sys.argv[0])

	def results(self, message, *args, **kws):
	    if self.isEnabledFor(custom_log_level):
		self.log(custom_log_level, message, *args, **kws)
	logging.Logger.results = results

	logging.basicConfig(filename=os.path.join(os.getcwd(),'results-'+caller+'.log'),
                            filemode='w',
                            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                            datefmt='%H:%M:%S',
                            level=custom_log_level)
	local_log = logging.getLogger(caller)

	#check status of tests and record it
        for (name, msg) in result.errors:
                if self._testMethodName == str(name).split(' ')[0]:
			local_log.results("Testcase "+str(test_case)+": ERROR")
			local_log.results("Testcase "+str(test_case)+":\n"+msg)
			passed = False
        for (name, msg) in result.failures:
                if self._testMethodName == str(name).split(' ')[0]:
			local_log.results("Testcase "+str(test_case)+": FAILED")
			local_log.results("Testcase "+str(test_case)+":\n"+msg)
			passed = False
        for (name, msg) in result.skipped:
                if self._testMethodName == str(name).split(' ')[0]:
			local_log.results("Testcase "+str(test_case)+": SKIPPED")
			passed = False
	if passed:
			local_log.results("Testcase "+str(test_case)+": PASSED")

    original_class.run = run
    return original_class
