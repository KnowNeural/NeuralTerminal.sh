# NeuralTerminal.sh

## QUICK INSTALL

```
wget -qO- https://raw.githubusercontent.com/KnowNeural/NeuralTerminal.sh/refs/heads/main/neural_install.sh | bash
```

## Options

| Option | Format | Description | Example |
|--------|--------|-------------|----------|
| `-t`, `--tag` | `--tag TAG` | Filter by tag (e.g., 'drift', 'gfm', 'pump', 'meme') | `--tag pump` |
| `-p`, `--pin` | `--pin SYMBOL` | Pin a token to the top of the display | `--pin BTC` |
| `-n`, `--number` | `--number N` | Show N lines (default: 25) | `--number 50` |
| `--long` | `--long` | Show only long signals | `--long` |
| `--short` | `--short` | Show only short signals | `--short` |
| `-h`, `--help` | `--help` | Show help message | `--help` |

## Display Columns

| Column | Description |
|--------|-------------|
| Symbol | Token/trading pair symbol |
| Price | Current price in base currency |
| Signal | Trading signal (L = Long, S = Short, - = Neutral) |
| EMA | Exponential Moving Average trend |
| RSI | Relative Strength Index |
| Change% | 5-minute price change percentage |
| Tags | Token categories/attributes |

## Example Usage

```bash
# Run with default settings
./neural_terminal.sh

# Show only GFM tokens with long signals
./neural_terminal.sh --tag GFM --long

# Pin multiple tokens and show top 50
./neural_terminal.sh --pin NEURAL --pin GFM --number 50

# Show only short signals for meme tokens
./neural_terminal.sh --tag meme --short
```

## Notes

- The display updates every 5 seconds
- Color coding: Green for positive changes, Red for negative
- RSI values range from 0 to 100
- EMA trend shows the strength and direction of the trend
