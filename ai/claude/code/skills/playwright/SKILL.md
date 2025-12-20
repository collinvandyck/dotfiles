---
name: playwright
description: Browser automation using Playwright for web scraping, testing, screenshots, and interaction. Use when the user needs to navigate websites, fill forms, click buttons, extract web content, take screenshots, or automate browser tasks.
---

# Playwright Browser Automation

Use Playwright to automate browser interactions when you need to:
- Navigate to web pages and interact with them
- Fill forms, click buttons, select options
- Extract content from dynamic/JavaScript-rendered pages
- Take screenshots or PDFs of web pages
- Test web application functionality
- Scrape data that requires JavaScript execution

## Quick Start

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://example.com")

    # Get page content
    content = page.content()

    # Take screenshot
    page.screenshot(path="screenshot.png")

    browser.close()
```

## Common Patterns

### Navigate and Extract Text

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://example.com")

    # Wait for content to load
    page.wait_for_load_state("networkidle")

    # Extract text from elements
    title = page.title()
    body_text = page.inner_text("body")

    # Query specific elements
    links = page.query_selector_all("a")
    for link in links:
        href = link.get_attribute("href")
        text = link.inner_text()
        print(f"{text}: {href}")

    browser.close()
```

### Fill Forms and Submit

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://example.com/login")

    # Fill form fields
    page.fill('input[name="username"]', 'user@example.com')
    page.fill('input[name="password"]', 'password123')

    # Click submit button
    page.click('button[type="submit"]')

    # Wait for navigation
    page.wait_for_url("**/dashboard**")

    browser.close()
```

### Take Screenshots

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()

    # Set viewport size
    page.set_viewport_size({"width": 1920, "height": 1080})

    page.goto("https://example.com")

    # Full page screenshot
    page.screenshot(path="full_page.png", full_page=True)

    # Element screenshot
    element = page.query_selector("header")
    if element:
        element.screenshot(path="header.png")

    # PDF (Chromium only)
    page.pdf(path="page.pdf", format="A4")

    browser.close()
```

### Wait for Dynamic Content

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://example.com")

    # Wait for specific element
    page.wait_for_selector(".dynamic-content")

    # Wait for element to be visible
    page.wait_for_selector(".loading", state="hidden")

    # Wait for network to be idle
    page.wait_for_load_state("networkidle")

    # Wait for specific text
    page.wait_for_selector("text=Success")

    browser.close()
```

### Handle Multiple Pages/Tabs

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context()

    # Open multiple pages
    page1 = context.new_page()
    page2 = context.new_page()

    page1.goto("https://example.com")
    page2.goto("https://example.org")

    # Handle popup
    with context.expect_page() as new_page_info:
        page1.click("a[target='_blank']")
    new_page = new_page_info.value

    context.close()
    browser.close()
```

### Execute JavaScript

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://example.com")

    # Execute JavaScript and get result
    result = page.evaluate("() => document.title")

    # Execute with arguments
    element_text = page.evaluate(
        "(selector) => document.querySelector(selector)?.textContent",
        "h1"
    )

    # Modify the page
    page.evaluate("() => { document.body.style.background = 'red'; }")

    browser.close()
```

### Handle Authentication

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)

    # HTTP authentication
    context = browser.new_context(
        http_credentials={"username": "user", "password": "pass"}
    )

    # Or with storage state (cookies/localStorage)
    # Save state after login
    page = context.new_page()
    page.goto("https://example.com/login")
    page.fill("#username", "user")
    page.fill("#password", "pass")
    page.click("button[type=submit]")
    page.wait_for_url("**/dashboard**")
    context.storage_state(path="auth.json")

    # Reuse state later
    context2 = browser.new_context(storage_state="auth.json")

    browser.close()
```

## Selectors Reference

Playwright supports multiple selector strategies:

| Selector | Example | Description |
|----------|---------|-------------|
| CSS | `page.click("button.submit")` | Standard CSS selector |
| Text | `page.click("text=Submit")` | Match by text content |
| XPath | `page.click("xpath=//button")` | XPath selector |
| ID | `page.click("#submit-btn")` | By element ID |
| Role | `page.click("role=button[name='Submit']")` | ARIA role |
| Placeholder | `page.fill("placeholder=Email")` | Input placeholder |
| Label | `page.fill("label=Email")` | Associated label |

## Requirements

Playwright must be installed:

```bash
pip install playwright
playwright install chromium  # or: playwright install
```

## Tips

1. **Always use headless mode** unless debugging: `launch(headless=True)`
2. **Set timeouts** for reliability: `page.set_default_timeout(30000)`
3. **Use `wait_for_selector`** before interacting with dynamic content
4. **Handle errors gracefully** with try/except blocks
5. **Close browsers** when done to free resources
6. **Use contexts** for isolation between sessions
