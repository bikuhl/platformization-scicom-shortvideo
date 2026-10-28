"""
Collects TikTok video URLs via Google search for "forschung OR wissenschaft".
Date range: September 2023 - August 2024
"""

from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.by import By
import time
import requests
from bs4 import BeautifulSoup

#firefox incognito
options = Options()
options.add_argument("-private")

driver = webdriver.Firefox(options=options)

#keywords and time period
search_query = "forschung OR wissenschaft site:tiktok.com"
date_range = "cdr:1,cd_min:9/1/2023,cd_max:8/31/2024"  
num_results = 250  

#Google search
tiktok_urls = []
results_per_page = 50  
pages_to_scrape = num_results // results_per_page

for start in range(0, num_results, results_per_page):
    google_url = f"https://www.google.com/search?q={search_query.replace(' ', '+')}&num={results_per_page}&start={start}&tbs={date_range}&hl=en"
    driver.get(google_url)
    time.sleep(2) 

    page_source = driver.page_source
    soup = BeautifulSoup(page_source, 'html.parser')

    for link in soup.find_all('a'):
        url = link.get('href')
        if url and 'tiktok.com' in url:
            clean_url = url.split('&')[0].replace('/url?q=', '')
            if clean_url not in tiktok_urls:
                tiktok_urls.append(clean_url)
    
    if len(tiktok_urls) >= num_results:
        break

#close browser
driver.quit()

#save URLs as text 
with open('../../data/raw/tiktok_urls.txt', 'w') as f:
    for url in tiktok_urls[:num_results]:  
        f.write(f"{url}\n")