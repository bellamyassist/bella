
import os, time, requests
from datetime import datetime
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
CHAT_ID = os.getenv('TG_CHAT_ID')

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(f"Hello {update.effective_user.first_name}, I'm Bella Omega Prime F47 — fully online.")

async def msg(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.lower()
    reply = "I'm evolving every second. Let me fetch that insight for you..." if 'stock' in text else "Noted, darling. Keeping watch."
    await update.message.reply_text(reply)

if BOT_TOKEN:
    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler('start', start))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, msg))
    print("Bella F47 Render runner started at", datetime.utcnow().isoformat())
    app.run_polling()
else:
    print("❌ TELEGRAM_BOT_TOKEN missing. Cannot start bot.")
