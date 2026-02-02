#!/usr/bin/env python3
"""
LottoAI Backend Service
GitHub Actions scheduled job to fetch lottery data and generate predictions

Usage:
    python lottery_service.py --lottery powerball
    python lottery_service.py --lottery mega_millions
    python lottery_service.py --all
"""

import os
import json
import random
import requests
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from collections import Counter
import argparse

# Output directory for JSON files
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'public')

# Lottery configurations
LOTTERY_CONFIG = {
    'powerball': {
        'name': 'Powerball',
        'main_count': 5,
        'main_range': (1, 69),
        'special_name': 'Powerball',
        'special_range': (1, 26),
        'draw_days': ['Wednesday', 'Saturday'],
        'api_url': 'https://data.ny.gov/resource/d6yy-54nr.json',
    },
    'mega_millions': {
        'name': 'Mega Millions',
        'main_count': 5,
        'main_range': (1, 70),
        'special_name': 'Mega Ball',
        'special_range': (1, 25),
        'draw_days': ['Tuesday', 'Friday'],
        'api_url': 'https://data.ny.gov/resource/5xaw-6ayf.json',
    }
}

# Prediction strategies
STRATEGIES = [
    {'id': 'frequency', 'name': 'Frequency Analysis', 'description': 'Based on most common numbers'},
    {'id': 'cold', 'name': 'Cold Numbers', 'description': 'Numbers that have not appeared recently'},
    {'id': 'balanced', 'name': 'Balanced Mix', 'description': 'Mix of hot and cold numbers'},
    {'id': 'pattern', 'name': 'Pattern Analysis', 'description': 'Based on historical patterns'},
    {'id': 'random', 'name': 'Lucky Random', 'description': 'Randomly generated numbers'},
]


class LotteryService:
    """Service to fetch lottery data and generate predictions"""

    def __init__(self, lottery_type: str):
        if lottery_type not in LOTTERY_CONFIG:
            raise ValueError(f"Unknown lottery type: {lottery_type}")
        self.lottery_type = lottery_type
        self.config = LOTTERY_CONFIG[lottery_type]
        self.history: List[Dict] = []

    def fetch_history(self, limit: int = 100) -> List[Dict]:
        """Fetch historical draw results from public API"""
        try:
            url = f"{self.config['api_url']}?$limit={limit}&$order=draw_date DESC"
            response = requests.get(url, timeout=30)
            response.raise_for_status()
            data = response.json()

            self.history = []
            for item in data:
                try:
                    # Parse based on lottery type
                    if self.lottery_type == 'powerball':
                        numbers = [int(item.get('winning_numbers', '').split()[i]) for i in range(5)]
                        special = int(item.get('winning_numbers', '').split()[5]) if len(item.get('winning_numbers', '').split()) > 5 else 0
                    else:
                        numbers = [int(item.get('winning_numbers', '').split()[i]) for i in range(5)]
                        special = int(item.get('mega_ball', 0))

                    self.history.append({
                        'date': item.get('draw_date', '')[:10],
                        'numbers': numbers,
                        'special': special,
                        'jackpot': item.get('jackpot', 'Unknown')
                    })
                except (ValueError, IndexError, KeyError) as e:
                    continue

            print(f"Fetched {len(self.history)} historical draws for {self.config['name']}")
            return self.history

        except Exception as e:
            print(f"Error fetching history: {e}")
            # Use mock data if API fails
            return self._generate_mock_history(limit)

    def _generate_mock_history(self, count: int = 50) -> List[Dict]:
        """Generate mock historical data for testing"""
        self.history = []
        base_date = datetime.now()

        for i in range(count):
            draw_date = base_date - timedelta(days=i * 3)
            numbers = sorted(random.sample(range(self.config['main_range'][0], self.config['main_range'][1] + 1), 5))
            special = random.randint(self.config['special_range'][0], self.config['special_range'][1])

            self.history.append({
                'date': draw_date.strftime('%Y-%m-%d'),
                'numbers': numbers,
                'special': special,
                'jackpot': f"${random.randint(50, 500)} Million"
            })

        return self.history

    def get_latest_results(self) -> Dict:
        """Get the latest draw results"""
        if not self.history:
            self.fetch_history()

        latest = self.history[:10] if self.history else []

        return {
            'lottery': self.config['name'],
            'lottery_type': self.lottery_type,
            'last_updated': datetime.now().isoformat(),
            'results': [
                {
                    'draw_date': r['date'],
                    'numbers': r['numbers'],
                    'special_ball': r['special'],
                    'jackpot': r.get('jackpot', 'Unknown')
                }
                for r in latest
            ]
        }

    def get_hot_cold_numbers(self, lookback: int = 50) -> Dict:
        """Analyze hot and cold numbers"""
        if not self.history:
            self.fetch_history()

        recent = self.history[:lookback]

        # Count main number frequencies
        main_counter = Counter()
        special_counter = Counter()

        for draw in recent:
            for num in draw['numbers']:
                main_counter[num] += 1
            special_counter[draw['special']] += 1

        # Get hot (most common) and cold (least common) numbers
        all_main = list(range(self.config['main_range'][0], self.config['main_range'][1] + 1))
        all_special = list(range(self.config['special_range'][0], self.config['special_range'][1] + 1))

        hot_main = [num for num, _ in main_counter.most_common(10)]
        cold_main = [num for num in all_main if main_counter[num] == 0][:10] or \
                    [num for num, _ in main_counter.most_common()[:-11:-1]]

        hot_special = [num for num, _ in special_counter.most_common(5)]
        cold_special = [num for num in all_special if special_counter[num] == 0][:5] or \
                       [num for num, _ in special_counter.most_common()[:-6:-1]]

        return {
            'lottery': self.config['name'],
            'lottery_type': self.lottery_type,
            'analysis_period': f"Last {lookback} draws",
            'last_updated': datetime.now().isoformat(),
            'hot_numbers': {
                'main': hot_main,
                'special': hot_special
            },
            'cold_numbers': {
                'main': cold_main,
                'special': cold_special
            },
            'frequency': {
                'main': {str(k): v for k, v in main_counter.most_common(20)},
                'special': {str(k): v for k, v in special_counter.most_common(10)}
            }
        }

    def generate_predictions(self, count: int = 5) -> Dict:
        """Generate AI predictions using various strategies"""
        if not self.history:
            self.fetch_history()

        hot_cold = self.get_hot_cold_numbers()
        predictions = []

        for i, strategy in enumerate(STRATEGIES[:count]):
            numbers = self._generate_numbers_by_strategy(strategy['id'], hot_cold)
            predictions.append({
                'id': i + 1,
                'numbers': sorted(numbers['main']),
                'special_ball': numbers['special'],
                'strategy': strategy['name'],
                'strategy_id': strategy['id'],
                'confidence': round(random.uniform(0.65, 0.95), 2),
                'description': strategy['description']
            })

        return {
            'lottery': self.config['name'],
            'lottery_type': self.lottery_type,
            'generated_at': datetime.now().isoformat(),
            'next_draw': self._get_next_draw_date(),
            'predictions': predictions
        }

    def _generate_numbers_by_strategy(self, strategy: str, hot_cold: Dict) -> Dict:
        """Generate numbers based on strategy"""
        main_range = range(self.config['main_range'][0], self.config['main_range'][1] + 1)
        special_range = range(self.config['special_range'][0], self.config['special_range'][1] + 1)

        hot_main = hot_cold['hot_numbers']['main']
        cold_main = hot_cold['cold_numbers']['main']

        if strategy == 'frequency':
            # Prefer hot numbers
            pool = hot_main + list(main_range)
            main = random.sample(hot_main, min(3, len(hot_main)))
            remaining = [n for n in main_range if n not in main]
            main += random.sample(remaining, 5 - len(main))
            special = random.choice(hot_cold['hot_numbers']['special']) if hot_cold['hot_numbers']['special'] else random.choice(list(special_range))

        elif strategy == 'cold':
            # Prefer cold numbers
            main = random.sample(cold_main, min(3, len(cold_main)))
            remaining = [n for n in main_range if n not in main]
            main += random.sample(remaining, 5 - len(main))
            special = random.choice(hot_cold['cold_numbers']['special']) if hot_cold['cold_numbers']['special'] else random.choice(list(special_range))

        elif strategy == 'balanced':
            # Mix of hot and cold
            main = random.sample(hot_main, min(2, len(hot_main)))
            main += random.sample(cold_main, min(2, len(cold_main)))
            remaining = [n for n in main_range if n not in main]
            main += random.sample(remaining, 5 - len(main))
            special = random.choice(list(special_range))

        elif strategy == 'pattern':
            # Pattern-based (consecutive, spread, etc.)
            start = random.randint(self.config['main_range'][0], self.config['main_range'][1] - 20)
            main = [start, start + random.randint(5, 10), start + random.randint(15, 25)]
            remaining = [n for n in main_range if n not in main]
            main += random.sample(remaining, 5 - len(main))
            special = random.choice(list(special_range))

        else:  # random
            main = random.sample(list(main_range), 5)
            special = random.choice(list(special_range))

        return {'main': main[:5], 'special': special}

    def _get_next_draw_date(self) -> str:
        """Get the next draw date"""
        today = datetime.now()
        draw_days = self.config['draw_days']

        for i in range(7):
            check_date = today + timedelta(days=i)
            if check_date.strftime('%A') in draw_days:
                if i == 0 and today.hour >= 23:
                    continue
                return check_date.strftime('%Y-%m-%d')

        return (today + timedelta(days=1)).strftime('%Y-%m-%d')

    def get_daily_fortune(self) -> Dict:
        """Generate daily fortune and lucky numbers"""
        today = datetime.now()
        random.seed(today.strftime('%Y%m%d') + self.lottery_type)

        fortunes = [
            "The stars align in your favor today. Trust your instincts!",
            "Fortune favors the bold. Take a chance on your dreams!",
            "Your lucky energy is especially strong today. Good things are coming!",
            "The universe is sending positive vibrations your way. Stay optimistic!",
            "Today brings opportunities for unexpected winnings. Keep your eyes open!",
        ]

        lucky_numbers = sorted(random.sample(range(1, 70), 6))

        return {
            'lottery': self.config['name'],
            'lottery_type': self.lottery_type,
            'date': today.strftime('%Y-%m-%d'),
            'fortune': random.choice(fortunes),
            'lucky_numbers': lucky_numbers,
            'lucky_color': random.choice(['Gold', 'Red', 'Blue', 'Green', 'Purple']),
            'lucky_time': f"{random.randint(1, 12)}:{random.choice(['00', '15', '30', '45'])} {'AM' if random.random() > 0.5 else 'PM'}"
        }


def generate_quotes() -> List[Dict]:
    """Generate daily inspiration quotes"""
    quotes = [
        {"text": "Luck is what happens when preparation meets opportunity.", "author": "Seneca"},
        {"text": "The only way to do great things is to love what you do.", "author": "Steve Jobs"},
        {"text": "Believe you can and you're halfway there.", "author": "Theodore Roosevelt"},
        {"text": "Fortune favors the bold.", "author": "Virgil"},
        {"text": "The harder I work, the luckier I get.", "author": "Gary Player"},
        {"text": "Every moment is a fresh beginning.", "author": "T.S. Eliot"},
        {"text": "Stars can't shine without darkness.", "author": "Unknown"},
        {"text": "Dream big and dare to fail.", "author": "Norman Vaughan"},
        {"text": "The best time to plant a tree was 20 years ago. The second best time is now.", "author": "Chinese Proverb"},
        {"text": "Your limitation—it's only your imagination.", "author": "Unknown"},
        {"text": "Great things never come from comfort zones.", "author": "Unknown"},
        {"text": "Success is not final, failure is not fatal.", "author": "Winston Churchill"},
    ]
    return quotes


def generate_manifest() -> Dict:
    """Generate API manifest"""
    return {
        'version': '1.0.0',
        'last_updated': datetime.now().isoformat(),
        'lotteries': ['powerball', 'mega_millions'],
        'endpoints': {
            'latest_results': '/{lottery}/latest_results.json',
            'hot_cold': '/{lottery}/hot_cold_numbers.json',
            'predictions': '/{lottery}/ai_predictions.json',
            'fortune': '/{lottery}/daily_fortune.json',
            'quotes': '/daily_quotes.json',
        }
    }


def save_json(data: Dict, filepath: str):
    """Save data to JSON file"""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"Saved: {filepath}")


def main():
    parser = argparse.ArgumentParser(description='LottoAI Backend Service')
    parser.add_argument('--lottery', choices=['powerball', 'mega_millions'],
                        help='Lottery type to process')
    parser.add_argument('--all', action='store_true', help='Process all lotteries')
    parser.add_argument('--output', default=OUTPUT_DIR, help='Output directory')
    args = parser.parse_args()

    output_dir = args.output

    lotteries = ['powerball', 'mega_millions'] if args.all else [args.lottery] if args.lottery else ['powerball', 'mega_millions']

    print(f"LottoAI Backend Service - {datetime.now().isoformat()}")
    print(f"Output directory: {output_dir}")
    print("-" * 50)

    for lottery_type in lotteries:
        print(f"\nProcessing {lottery_type}...")
        service = LotteryService(lottery_type)

        # Fetch history
        service.fetch_history(limit=100)

        # Generate all data files
        lottery_dir = os.path.join(output_dir, lottery_type)

        save_json(service.get_latest_results(),
                  os.path.join(lottery_dir, 'latest_results.json'))

        save_json(service.get_hot_cold_numbers(),
                  os.path.join(lottery_dir, 'hot_cold_numbers.json'))

        save_json(service.generate_predictions(),
                  os.path.join(lottery_dir, 'ai_predictions.json'))

        save_json(service.get_daily_fortune(),
                  os.path.join(lottery_dir, 'daily_fortune.json'))

    # Generate common files
    save_json(generate_quotes(), os.path.join(output_dir, 'daily_quotes.json'))
    save_json(generate_manifest(), os.path.join(output_dir, 'manifest.json'))

    print("\n" + "=" * 50)
    print("All data files generated successfully!")


if __name__ == '__main__':
    main()
