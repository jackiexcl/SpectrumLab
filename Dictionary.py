'''
Created on 6 Nov 2017

@author: alethea
'''

from xlrd import open_workbook
import xlrd

from DictObject import yearEntry

totalDict = {} # dictionary: keys = years 1999-2016, values = dictionaries mapping subsidiaries to parent companies
subSet = set() # set of subsidiaries

def createDict(data):
    for sheet in data.sheets(): # year by year
        subToPar = {} # dictionary mapping subsidiaries (including parent company) to parent companies
        numRows = sheet.nrows # number of rows in each sheet
        for row in range(1, numRows): # skip header row
            parent = "" 
            for col in range(2): 
                if col == 0: # parent company col
                    parent = sheet.cell(row,col).value
                    if parent != xlrd.empty_cell.value: # so that we don't add empty cells to the dict
                        parent = str(parent)
                        if parent not in subToPar: # parent company not yet intialized in subToPar
                            subToPar[parent] = []
                            subToPar[parent].append(parent) # include parent company as subsidiary
                if col == 1: # subsidiary col
                    if parent != xlrd.empty_cell.value: # so that we don't add empty cells to the dict
                        parent = str(parent)
                        
                        # don't add subsidiary companies that have non-acsii characters
                        try:
                            subToPar[parent].append(str(sheet.cell(row,col).value)) # add subsidiary to list
                        except:
                            pass
                         
        item = yearEntry(int(sheet.name), subToPar)
        totalDict[item.numYear] = item.subToPar # map subToPar dictionary to year
        
    for year, dict in totalDict.items():
        for k,v in dict.items():
            for sub in v:
                subSet.add(sub)
    return subSet
        
if __name__ == '__main__':
    data = open_workbook('web-scraping.xlsx')
    print createDict(data)
