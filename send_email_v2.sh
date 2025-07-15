#!/bin/bash

# Configuration
SMTP_SERVER="SMTP.MYDOMAIN.COM"		# Replace with SMTP server
SMTP_PORT="25"                  	# 25, 587, or 465
FROM="test.mydomain.com"			# Sender email
TO="tickles.mydomain.com"      		# Recipient email
SUBJECT="Test Email"
BODY="Teamwork makes the dream work"

# Create the email content with proper formatting
send_email() {
  # Wait for server greeting
  read -r response
  echo "SERVER: $response" >&2

  # Send commands with proper CRLF and timing
  printf "EHLO example.com\r\n"
  sleep 1
  printf "MAIL FROM:<%s>\r\n" "$FROM"
  sleep 1
  printf "RCPT TO:<%s>\r\n" "$TO"
  sleep 1
  printf "DATA\r\n"
  sleep 1
  printf "From: %s\r\n" "$FROM"
  printf "To: %s\r\n" "$TO"
  printf "Subject: %s\r\n" "$SUBJECT"
  printf "\r\n"  # Empty line between headers and body
  printf "%s\r\n" "$BODY"
  printf ".\r\n"  # End of DATA with proper CRLF
  sleep 1
  printf "QUIT\r\n"
}

# Connect to server (either telnet or netcat)
if command -v nc &>/dev/null; then
  send_email | nc -N "$SMTP_SERVER" "$SMTP_PORT"
elif command -v telnet &>/dev/null; then
  send_email | telnet "$SMTP_SERVER" "$SMTP_PORT"
else
  echo "Error: Neither netcat nor telnet found"
  exit 1
fi

echo "Email sent successfully (check your recipient's inbox)"