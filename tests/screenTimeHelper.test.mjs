import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import * as ScreenTime from '../lib/screenTimeHelper.js';

describe('screenTimeHelper.js - Local Screen Time Engine', () => {
    describe('categorizeApp', () => {
        it('categorizes developer editors and terminals into Development', () => {
            assert.equal(ScreenTime.categorizeApp('code'), 'Development');
            assert.equal(ScreenTime.categorizeApp('Code'), 'Development');
            assert.equal(ScreenTime.categorizeApp('kitty'), 'Development');
            assert.equal(ScreenTime.categorizeApp('alacritty'), 'Development');
            assert.equal(ScreenTime.categorizeApp('neovim'), 'Development');
        });

        it('categorizes web browsers into Browsing', () => {
            assert.equal(ScreenTime.categorizeApp('google-chrome'), 'Browsing');
            assert.equal(ScreenTime.categorizeApp('firefox'), 'Browsing');
            assert.equal(ScreenTime.categorizeApp('zen-browser'), 'Browsing');
            assert.equal(ScreenTime.categorizeApp('brave-browser'), 'Browsing');
        });

        it('categorizes chat and communication apps into Social', () => {
            assert.equal(ScreenTime.categorizeApp('discord'), 'Social');
            assert.equal(ScreenTime.categorizeApp('vesktop'), 'Social');
            assert.equal(ScreenTime.categorizeApp('telegram-desktop'), 'Social');
            assert.equal(ScreenTime.categorizeApp('slack'), 'Social');
        });

        it('categorizes audio and video players into Media', () => {
            assert.equal(ScreenTime.categorizeApp('spotify'), 'Media');
            assert.equal(ScreenTime.categorizeApp('vlc'), 'Media');
            assert.equal(ScreenTime.categorizeApp('mpv'), 'Media');
        });

        it('categorizes documents and productivity tools into Work', () => {
            assert.equal(ScreenTime.categorizeApp('obsidian'), 'Work');
            assert.equal(ScreenTime.categorizeApp('libreoffice'), 'Work');
            assert.equal(ScreenTime.categorizeApp('notion-app'), 'Work');
        });

        it('falls back to Other for unrecognized or empty inputs', () => {
            assert.equal(ScreenTime.categorizeApp('unknown_xyz'), 'Other');
            assert.equal(ScreenTime.categorizeApp(''), 'Other');
            assert.equal(ScreenTime.categorizeApp(null), 'Other');
        });
    });

    describe('formatSeconds', () => {
        it('formats zero and small durations in minutes', () => {
            assert.equal(ScreenTime.formatSeconds(0), '0m');
            assert.equal(ScreenTime.formatSeconds(45), '0m');
            assert.equal(ScreenTime.formatSeconds(125), '2m');
        });

        it('formats hours and minutes accurately', () => {
            assert.equal(ScreenTime.formatSeconds(3600), '1j 0m');
            assert.equal(ScreenTime.formatSeconds(5400), '1j 30m');
            assert.equal(ScreenTime.formatSeconds(9120), '2j 32m');
        });

        it('handles negative or invalid values safely', () => {
            assert.equal(ScreenTime.formatSeconds(-50), '0m');
            assert.equal(ScreenTime.formatSeconds(NaN), '0m');
            assert.equal(ScreenTime.formatSeconds(null), '0m');
        });
    });

    describe('aggregateDaily', () => {
        it('aggregates app usage map into sorted top apps and category breakdown', () => {
            const rawMap = {
                'code': 7200,      // 2h Development
                'firefox': 3600,   // 1h Browsing
                'discord': 1800    // 30m Social
            };

            const result = ScreenTime.aggregateDaily(rawMap);
            assert.equal(result.totalSec, 12600);
            assert.equal(result.formattedTotal, '3j 30m');

            // Top apps sorted descending
            assert.equal(result.topApps.length, 3);
            assert.equal(result.topApps[0].appClass, 'code');
            assert.equal(result.topApps[0].seconds, 7200);
            assert.equal(result.topApps[0].category, 'Development');
            assert.equal(result.topApps[0].percentage, 57);

            assert.equal(result.topApps[1].appClass, 'firefox');
            assert.equal(result.topApps[1].seconds, 3600);

            assert.equal(result.topApps[2].appClass, 'discord');
            assert.equal(result.topApps[2].seconds, 1800);

            // Categories summary
            assert.ok(result.categories.length >= 3);
            const devCat = result.categories.find(c => c.name === 'Development');
            assert.ok(devCat);
            assert.equal(devCat.seconds, 7200);
            assert.equal(devCat.percentage, 57);
            assert.equal(devCat.color, '#60a5fa');
        });

        it('handles empty or malformed maps without crashing', () => {
            const emptyResult = ScreenTime.aggregateDaily({});
            assert.equal(emptyResult.totalSec, 0);
            assert.equal(emptyResult.formattedTotal, '0m');
            assert.deepEqual(emptyResult.topApps, []);
            assert.deepEqual(emptyResult.categories, []);

            const nullResult = ScreenTime.aggregateDaily(null);
            assert.equal(nullResult.totalSec, 0);
            assert.deepEqual(nullResult.topApps, []);
        });
    });

    describe('getCategoryColor', () => {
        it('provides distinctive Apple Obsidian accent colors for categories', () => {
            assert.equal(ScreenTime.getCategoryColor('Development'), '#60a5fa');
            assert.equal(ScreenTime.getCategoryColor('Browsing'), '#4ade80');
            assert.equal(ScreenTime.getCategoryColor('Work'), '#fbbf24');
            assert.equal(ScreenTime.getCategoryColor('Social'), '#a78bfa');
            assert.equal(ScreenTime.getCategoryColor('Media'), '#f472b6');
            assert.equal(ScreenTime.getCategoryColor('Other'), '#94a3b8');
        });
    });
});
