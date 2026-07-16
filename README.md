# KOTelegram  

A KOReader plugin that sends your book highlights and notes directly to a Telegram bot.  

## Installation  
Copy the plugin folder to your KOReader `plugins` directory.  

## How to setup  
### Create your Telegram Bot  
Send `/newbot` to [@BotFather](https://t.me/botfather) and follow the instructions to name your bot.  
BotFather will give you an **API Token**. Save it.  
Start a chat with your new bot and send any message.  
Once started the bot chat visit `https://api.telegram.org/bot<yourToken>/getUpdates` to see the chatID  

### Configure the plugin  
In `config.txt` file located in the plugin folder:  
Paste your **API Token** in first line and your **ChatID** in the second line.  
Save the file and your plugin is ready to use.  

## Known Issues  
* **Sync Trigger:** Queued highlights from offline sessions are only sent when you create a new highlight after reconnecting.  
