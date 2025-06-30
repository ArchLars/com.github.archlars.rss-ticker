# RSS News Ticker

A simple KDE Plasma 6 widget that scrolls RSS headlines across your panel. It fetches today's articles from a configurable RSS feed and lets you open a headline in your browser with a click.

## Features
- Displays today's RSS headlines in a marquee
- Clickable headlines open the news article
- Adjustable update interval and scroll speed
- Optional fade transition on day change
- Configurable widget width for panel integration

## Installation
1. Clone this repository.
2. Install the plasmoid:
   ```
   plasmapkg2 --type plasmoid -i package
   ```
   You can also copy the `package` directory to `~/.local/share/plasma/plasmoids/com.github.archlars.rss-ticker`.

## Usage
Add the widget to your Plasma panel and open its settings to configure the RSS URL, update interval, scroll speed and other options.

## Development
The code lives in `package/contents/ui` and is written in QML with a small JavaScript helper. Contributions are welcome under the terms of the MIT license found in `LICENSE`.
