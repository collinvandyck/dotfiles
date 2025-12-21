---
name: playwright
description: Browser automation using Playwright for web scraping, testing, screenshots, and interaction. Use when the user needs to navigate websites, fill forms, click buttons, extract web content, take screenshots, or automate browser tasks.
---

# Playwright Browser Automation

## IMPORTANT: Handling Authentication

When automating pages that require login (Google, GitHub, internal tools, etc.):

1. **First, check if a profile exists** for the service (e.g., `google`, `github`)
2. **Use the persistent context** with the saved profile
3. **If you hit a login page or 401**, ask the user:
   > "This page requires authentication. Would you like to set up a saved session? Run:
   > `python3 ~/.claude/scripts/playwright-auth.py login <profile-name>`
   > then I can access it automatically."

**Signs you need authentication:**
- Page redirects to a login/OAuth page
- HTTP 401/403 responses
- Page title contains "Sign in", "Login", "Authenticate"
- Page content shows login form instead of expected content

**Available profiles** are stored in `~/.playwright-profiles/`. Check with:
```bash
python3 ~/.claude/scripts/playwright-auth.py list
```

---

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

## Authenticated Sessions (OAuth/Google Login)

For pages requiring authentication (Google, GitHub, etc.), use the **two-phase workflow**:

### Phase 1: Manual Login (User Does This Once)

Have the user create a persistent browser profile by logging in manually:

```bash
# User runs this to login and save session
python3 ~/.claude/scripts/playwright-auth.py login google

# Or with a specific starting URL
python3 ~/.claude/scripts/playwright-auth.py login google --url https://console.cloud.google.com
```

This opens a real browser where the user completes OAuth manually. The session (cookies, localStorage) is saved to `~/.playwright-profiles/google/`.

### Phase 2: Automated Access (Claude Uses This)

Use the saved profile in automation scripts:

```python
from playwright.sync_api import sync_playwright
from pathlib import Path

PROFILE_PATH = Path.home() / ".playwright-profiles" / "google"

with sync_playwright() as p:
    # Use persistent context to load saved session
    context = p.chromium.launch_persistent_context(
        user_data_dir=str(PROFILE_PATH),
        headless=True,  # Can run headless now that we're authenticated
        viewport={"width": 1280, "height": 900},
        args=["--disable-blink-features=AutomationControlled"],
    )

    page = context.pages[0] if context.pages else context.new_page()

    # Navigate to authenticated page - session cookies are loaded
    page.goto("https://console.cloud.google.com")
    page.wait_for_load_state("networkidle")

    # Now you can interact with the authenticated UI
    print(page.title())

    context.close()
```

### Auth Helper Commands

```bash
# List saved profiles
python3 ~/.claude/scripts/playwright-auth.py list

# Check profile status
python3 ~/.claude/scripts/playwright-auth.py check google

# Open browser with saved session (for debugging)
python3 ~/.claude/scripts/playwright-auth.py open google https://myapp.com

# Delete a profile
python3 ~/.claude/scripts/playwright-auth.py delete google
```

### Important Notes for Authenticated Sessions

1. **Always use `launch_persistent_context`** - not `launch()` + `new_context()`
2. **Add `--disable-blink-features=AutomationControlled`** - reduces bot detection
3. **Sessions expire** - if auth stops working, user needs to re-run the login phase
4. **Profile names are arbitrary** - use descriptive names like `google`, `github-work`, `staging`
5. **Headless works after login** - initial login must be visible, but subsequent automation can be headless

### Detecting Auth Issues

```python
def check_for_auth_redirect(page):
    """
    Check if we've been redirected to a login page.
    Call this after navigation to detect auth issues.
    Returns (needs_auth: bool, reason: str)
    """
    url = page.url.lower()
    title = page.title().lower()

    # Common OAuth/login URL patterns
    auth_url_patterns = [
        "accounts.google.com",
        "login", "signin", "sign-in", "sign_in",
        "auth", "oauth", "sso",
        "github.com/login",
        "identity",
    ]

    # Common login page title patterns
    auth_title_patterns = [
        "sign in", "log in", "login", "authenticate",
        "authorization", "access denied", "unauthorized",
    ]

    for pattern in auth_url_patterns:
        if pattern in url:
            return True, f"Redirected to auth URL: {page.url}"

    for pattern in auth_title_patterns:
        if pattern in title:
            return True, f"Login page detected: {page.title()}"

    return False, ""

# Usage after navigation:
page.goto("https://console.cloud.google.com")
page.wait_for_load_state("networkidle")

needs_auth, reason = check_for_auth_redirect(page)
if needs_auth:
    print(f"Authentication required: {reason}")
    print("User should run: python3 ~/.claude/scripts/playwright-auth.py login google")
```

### Checking if Session is Valid

```python
def is_logged_in(page, check_url, expected_element):
    """Check if session is still valid."""
    page.goto(check_url)
    try:
        page.wait_for_selector(expected_element, timeout=5000)
        return True
    except:
        return False

# Example: Check Google login
if not is_logged_in(page, "https://myaccount.google.com", "[data-email]"):
    print("Session expired! User needs to run: playwright-auth.py login google")
```

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
