import unittest
import os

os.environ["GNC_UNINSTALLED"] = "1"

from test import test_support

from test_book import TestBook
from test_account import TestAccount
from test_split import TestSplit
from test_transaction import TestTransaction
from test_business import TestBusiness
from test_commodity import TestCommodity, TestCommodityNamespace

def test_main():
    test_support.run_unittest(TestBook, TestAccount, TestSplit, TestTransaction, TestBusiness, TestCommodity, TestCommodityNamespace)

if __name__ == '__main__':
    test_main()
