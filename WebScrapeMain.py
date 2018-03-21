'''
Created on 8 Nov 2017

@author: alethea
'''

# setting up libraries
from Dictionary import createDict
# from DictObject import yearEntry
from xlrd import open_workbook
from selenium import webdriver
from selenium.webdriver.support.ui import Select

import xlwt
wb = xlwt.Workbook(encoding="utf-8")
ws1 = wb.add_sheet('Sheet 1',cell_overwrite_ok=True) # sheet 1 contains all the webscraped data
ws2 = wb.add_sheet('Sheet 2',cell_overwrite_ok=True) # sheet 2 contains two list of subsidiary companies: 1) returned results 2) did not return results
    
# initializing variables    
rowTracker = 1 # to track row in excel spreadsheet
subsWithResults = set([]) # set of subsidiaries that are returning results
subsWithoutResults = set([]) # set of subsidiaries that are NOT returning results


# scraping
def extractData(sub):
    global rowTracker

    # number of rows = number of call sign/lease IDs: -2 from row_count two remove header/footer rows
    row_count = len(driver.find_elements_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table/tbody/tr[5]/td/table[1]/tbody[1]/tr")) - 2
    
    # number of cols - need to use tr[2<=x<=row_count-1] and not header row, and -1 to remove row number
    # col_count = len(driver.find_elements_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table/tbody/tr[5]/td/table[1]/tbody[1]/tr[2]/td")) - 1
    # row num needs to start from 2 to exclude header row, and write subsidiary name in col 0
    for numR in range(2,row_count+2):
        row = driver.find_elements_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table/tbody/tr[5]/td/table[1]/tbody[1]/tr[" + str(numR) + "]/td")
        numC = 0
        for value in row:
            if numC == 0:
                ws1.row(rowTracker).write(numC, sub)
                subsWithResults.add(sub) # keep adding subsidiaries that return results to set
            elif numC > 0:
                ws1.row(rowTracker).write(numC, value.text)
            numC += 1
            
        callSignDataButton = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table/tbody/tr[5]/td/table[1]/tbody/tr[" + str(numR) + "]/td[2]/a")
        callSignDataButton.click()  
    
        callSignData(rowTracker,numC)
         
        rowTracker += 1
    
    try:
        nextPage = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table/tbody/tr[5]/td/table[2]/tbody/tr/td/table/tbody/tr/td[3]/a")
        nextPage.click()
        extractData(sub) # recursive function
    except:
        pass
    
def callSignData(rowNum,colNum):
    # scrape market section
    market = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[8]/td[2]")
    ws1.row(rowNum).write(colNum, market.text)
    submarket = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[9]/td[2]")
    ws1.row(rowNum).write(colNum+1, submarket.text)
    channelBlock = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[8]/td[4]")
    ws1.row(rowNum).write(colNum+2, channelBlock.text)
    associatedFreq = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[9]/td[4]")
    ws1.row(rowNum).write(colNum+3, associatedFreq.text)
    
    # scrape dates section
    grant = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[11]/td[2]")
    ws1.row(rowNum).write(colNum+4, grant.text)
    effective = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[12]/td[2]")
    ws1.row(rowNum).write(colNum+5, effective.text)
    expiration = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[11]/td[4]")
    ws1.row(rowNum).write(colNum+6, expiration.text)
    cancellation = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[12]/td[4]")
    ws1.row(rowNum).write(colNum+7, cancellation.text)
        
    # scrape buildout deadlines
    firstBD = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[15]/td[2]")
    ws1.row(rowNum).write(colNum+8, firstBD.text)
    secondBD = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[15]/td[4]")
    ws1.row(rowNum).write(colNum+9, secondBD.text)
        
    # scrape licensee ID
    licenseeID = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[4]/td/table/tbody/tr[2]/td[2]") 
    ws1.row(rowNum).write(colNum+10, licenseeID.text)
        
    # click 'market' tab
    marketTab = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[1]/tbody/tr[2]/td/a[2]")
    marketTab.click()
    # NOTE: Market tab takes quite long to load
    
    # scrape auction data - just the text and not the link
    auction = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/div/table[2]/tbody/tr[2]/td/table/tbody/tr[4]/td[2]")
    ws1.row(rowNum).write(colNum+11, auction.text)
    
    # return to results    
    returnToResults = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/table/tbody/tr[2]/td/span[3]/a[2]")
    returnToResults.click()
    
def subSearch(sub):
    
    # click the required radio service code options
    rsc = Select(driver.find_element_by_xpath("//select[@name='radioservicecode']"))
    radioServiceCodes = ["AH", "AT", "AW", "CN", "CW", "CY", "LD", "SG", "SL", "SP", "SY", "TZ", "WP", "WU", "WX", "WY", "WZ"] 
    for value in radioServiceCodes:
        rsc.select_by_value(value)
    
    # fill out input name of subsidiary
    inputSub = driver.find_element_by_xpath("//input[@name='fiOwnerName']")
    inputSub.send_keys(sub) # input subsidiary
    
    # click search button
    search = driver.find_element_by_xpath("//input[@src='external/buttons/newsearch-blue.gif']")
    search.click()
    
    # start web scraping the subsidiary data
    extractData(sub)
      
    # go back to new search
    newSearch = driver.find_element_by_xpath("/html/body/table[4]/tbody/tr/td[2]/table/tbody/tr[2]/td/span[1]/a[2]")
    newSearch.click()


if __name__ == '__main__':
    driver = webdriver.Chrome('/Users/admin/Desktop/WebScrapingToh/chromedriver')
    data = open_workbook('web-scraping.xlsx')  
    listofbidder = open_workbook('Auction58Bidders.xlsx')
    url = 'http://wireless2.fcc.gov/UlsApp/LicArchive/searchArchive.jsp'
    driver.get(url)
    
    # write the header row in bold font
    font = xlwt.Font()
    font.bold = True
    style = xlwt.XFStyle() 
    style.font = font 
    
    # create header row in spreadsheet
    headerRow = ["Subsidiary","Call Sign/Lease ID", "Name", "FRN", "Radio Service", "Status", "Version", "Last Action Date", "Market", "Submarket", "Channel Block", "Associated Frequencies (MHz)", "Grant", "Effective", "Expiration", "Cancellation", "1st Buildout Deadline", "2nd Buildout Deadline", "Licensee ID", "Auction"]
    for i in range(0,len(headerRow)):
        ws1.row(0).write(i, headerRow[i],style)
    
    # single search
    #subSearch("Chariton Valley Communication Corporation, Inc.")
    

    # actual implementation: createDict(data) returns a set of all the subsidiary companies (so this removes duplicates)
    for subsidiary in createDict(listofbidder): #supposed to replace listofbidder with data here for all scraping
        subSearch(subsidiary)
 
    # set of subsidiaries that are NOT returning results
    #subsWithoutResults = createDict(data) - subsWithResults
    
    #ws2.row(0).write(0, "Returned Results",style)
    #ws2.row(0).write(1, "No Results",style)
    
    #idx1 = 1
    #for sub in subsWithResults:
    #   ws2.row(idx1).write(0, sub)
   #     idx1+=1
     
    #idx2 = 1
    #for sub in subsWithoutResults:
     #   ws2.row(idx2).write(1, sub)
      #  idx2+=1
    
    wb.save('/Users/admin/Desktop/WebScrapingToh/Spreadsheet_test.xls')
    
    driver.quit()
