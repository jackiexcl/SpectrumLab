'''
Created on 24 Oct 2017

@author: alethea
'''

class yearEntry(object):
    
    # constructor to create each year and its value (dict of subsidiaries mapped to parent company) as an object
    def __init__(self, numYear, subToPar):
            self.numYear = numYear
            self.subToPar = subToPar
