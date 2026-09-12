#!/usr/bin/env python3
"""
Fetch publication dates for all lectures in the playlist CSV.
Respects rate limits with concurrency ≤ 3 and exponential backoff.
"""

import asyncio
import csv
import json
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from io import StringIO
from typing import Optional

import requests
from bs4 import BeautifulSoup

MAX_CONCURRENCY = 3
MAX_RETRIES = 4
INITIAL_BACKOFF = 2
TIMEOUT = 20

HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
}

semaphore = None
request_session = None


def parse_date(date_str: str) -> Optional[str]:
    """Parse various date formats to YYYY-MM-DD."""
    if not date_str:
        return None
    
    # Try ISO format (2026-03-22T12:31:51+00:00)
    match = re.match(r'(\d{4}-\d{2}-\d{2})', date_str)
    if match:
        return match.group(1)
    
    # Try "Mar 22, 2026" format
    try:
        dt = datetime.strptime(date_str, '%b %d, %Y')
        return dt.strftime('%Y-%m-%d')
    except ValueError:
        pass
    
    # Try "March 22, 2026" format
    try:
        dt = datetime.strptime(date_str, '%B %d, %Y')
        return dt.strftime('%Y-%m-%d')
    except ValueError:
        pass
    
    return None


def fetch_with_retry_sync(url: str) -> Optional[str]:
    """Fetch URL with retry and exponential backoff using requests."""
    global request_session
    for attempt in range(MAX_RETRIES + 1):
        try:
            response = request_session.get(url, timeout=TIMEOUT, headers=HEADERS)
            if response.status_code == 429:
                if attempt < MAX_RETRIES:
                    wait_time = INITIAL_BACKOFF * (2 ** attempt)
                    print(f"  429 for {url[:50]}..., retry in {wait_time}s", file=sys.stderr)
                    time.sleep(wait_time)
                    continue
                return None
            if response.status_code != 200:
                return None
            return response.text
        except Exception as e:
            if attempt < MAX_RETRIES:
                wait_time = INITIAL_BACKOFF * (2 ** attempt)
                time.sleep(wait_time)
                continue
            return None
    return None


def get_maven_date(url: str) -> Optional[str]:
    """Extract date from Maven session page using JSON-LD or page content."""
    html = fetch_with_retry_sync(url)
    if not html:
        return None
    
    soup = BeautifulSoup(html, 'html.parser')
    
    # Try JSON-LD first (most reliable)
    for script in soup.find_all('script', type='application/ld+json'):
        try:
            data = json.loads(script.string)
            if isinstance(data, dict):
                for key in ['uploadDate', 'datePublished', 'startDate']:
                    if key in data:
                        return parse_date(data[key])
        except:
            pass
    
    # Fall back: look for og:video:release_date or similar meta tags
    for meta_prop in ['og:video:release_date', 'article:published_time', 'date']:
        meta = soup.find('meta', property=meta_prop) or soup.find('meta', attrs={'name': meta_prop})
        if meta and meta.get('content'):
            date = parse_date(meta.get('content'))
            if date:
                return date
    
    return None


def get_youtube_date(url: str) -> Optional[str]:
    """Extract upload date from YouTube page."""
    html = fetch_with_retry_sync(url)
    if not html:
        return None
    
    # Look for dateText in page content (human readable date)
    match = re.search(r'"dateText"\s*:\s*\{"simpleText"\s*:\s*"([^"]+)"', html)
    if match:
        return parse_date(match.group(1))
    
    # Fall back to uploadDate in JSON
    match = re.search(r'"uploadDate"\s*:\s*"([^"]+)"', html)
    if match:
        return parse_date(match.group(1))
    
    return None


def get_substack_date(url: str) -> Optional[str]:
    """Extract publication date from Substack page using JSON-LD or meta tags."""
    html = fetch_with_retry_sync(url)
    if not html:
        return None
    
    soup = BeautifulSoup(html, 'html.parser')
    
    # Try JSON-LD first
    for script in soup.find_all('script', type='application/ld+json'):
        try:
            data = json.loads(script.string)
            if isinstance(data, dict) and 'datePublished' in data:
                return parse_date(data['datePublished'])
            if isinstance(data, list):
                for item in data:
                    if isinstance(item, dict) and 'datePublished' in item:
                        return parse_date(item['datePublished'])
        except:
            pass
    
    # Fall back to meta tag
    meta = soup.find('meta', property='article:published_time')
    if meta and meta.get('content'):
        return parse_date(meta.get('content'))
    
    return None


def get_zoom_date(url: str) -> Optional[str]:
    """Try to extract date from Zoom recording page."""
    html = fetch_with_retry_sync(url)
    if not html:
        return None
    
    # Zoom recordings sometimes have dates in the page
    soup = BeautifulSoup(html, 'html.parser')
    
    # Check for date in meta tags
    for meta in soup.find_all('meta'):
        prop = meta.get('property', '') or meta.get('name', '')
        if 'date' in prop.lower():
            date = parse_date(meta.get('content', ''))
            if date:
                return date
    
    # Try to find date pattern in page
    match = re.search(r'(\d{4}-\d{2}-\d{2})', html)
    if match:
        return match.group(1)
    
    return None


def get_source_type(url: str) -> str:
    """Determine the source type from URL."""
    url_lower = url.lower()
    
    if 'youtube.com' in url_lower or 'youtu.be' in url_lower:
        return 'youtube'
    if 'maven.com/p/' in url_lower:
        return 'maven'
    if 'maven-hq.zoom.us' in url_lower or 'zoom.us/rec' in url_lower:
        return 'zoom'
    if any(domain in url_lower for domain in [
        'substack.com', 'lennysnewsletter.com', 'news.aakashg.com',
        'thehellopm.substack.com', 'theskip.substack.com', 'suprainsider.substack.com'
    ]):
        return 'substack'
    if 'vellum.ai' in url_lower:
        return 'vellum'
    
    return 'unknown'


def get_publication_date(url: str) -> Optional[str]:
    """Get publication date for a URL based on its source type."""
    source_type = get_source_type(url)
    
    if source_type == 'maven':
        return get_maven_date(url)
    elif source_type == 'youtube':
        return get_youtube_date(url)
    elif source_type == 'substack':
        return get_substack_date(url)
    elif source_type == 'zoom':
        return get_zoom_date(url)
    else:
        # For unknown sources, try substack-style extraction as fallback
        return get_substack_date(url)


def process_row(args) -> dict:
    """Process a single row and add publication date."""
    row, idx = args
    url = row.get('Link', '')
    title = row.get('Title', '')
    
    date = get_publication_date(url)
    row['Published'] = date or ''
    
    status = '✓' if date else '?'
    print(f"[{idx:3d}] {status} {title[:50]}...", file=sys.stderr)
    
    return row


def main():
    global request_session
    request_session = requests.Session()
    
    # Read input CSV
    with open('playlist/lectures.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    
    print(f"Processing {len(rows)} rows with concurrency={MAX_CONCURRENCY}", file=sys.stderr)
    
    # Process rows with thread pool for concurrency
    with ThreadPoolExecutor(max_workers=MAX_CONCURRENCY) as executor:
        args_list = [(row, idx) for idx, row in enumerate(rows)]
        results = list(executor.map(process_row, args_list))
    
    # Sort by Published date (newest first), rows without dates go to bottom
    def sort_key(row):
        pub = row.get('Published', '')
        if pub:
            return (0, pub)  # Dated rows first, sorted by date descending is done by reversing
        return (1, '')  # Undated rows last
    
    # Sort newest first: dated rows sorted descending, then undated
    dated = [r for r in results if r.get('Published')]
    undated = [r for r in results if not r.get('Published')]
    
    dated.sort(key=lambda r: r['Published'], reverse=True)
    sorted_results = dated + undated
    
    # Write output CSV with new column order
    fieldnames = ['Link', 'Title', 'Duplicate', 'Source', 'Added', 'Published']
    
    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
    writer.writeheader()
    for row in sorted_results:
        # Ensure all fields exist
        for field in fieldnames:
            if field not in row:
                row[field] = ''
        writer.writerow(row)
    
    # Summary
    dated_count = len(dated)
    undated_count = len(undated)
    print(f"\n=== Summary ===", file=sys.stderr)
    print(f"Dates found: {dated_count}", file=sys.stderr)
    print(f"Dates not found: {undated_count}", file=sys.stderr)
    
    if dated:
        print(f"\nTop 5 newest:", file=sys.stderr)
        for row in sorted_results[:5]:
            print(f"  {row['Published']}: {row['Title'][:50]}...", file=sys.stderr)


if __name__ == '__main__':
    main()
