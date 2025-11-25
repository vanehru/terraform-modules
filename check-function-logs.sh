#!/bin/bash

# Check Function App Logs
set -e

echo "🔍 Checking Function App Deployment..."

# Replace with your actual Function App name
FUNCTION_APP_NAME="$1"

if [ -z "$FUNCTION_APP_NAME" ]; then
    echo "❌ Please provide Function App name:"
    echo "Usage: ./check-function-logs.sh <function-app-name>"
    echo ""
    echo "Examples:"
    echo "  ./check-function-logs.sh demo-rpg-python-l0svei"
    echo "  ./check-function-logs.sh your-function-app-name"
    exit 1
fi

echo "📋 Function App: $FUNCTION_APP_NAME"

# Test if Function App exists
echo "🧪 Testing Function App availability..."
curl -I "https://$FUNCTION_APP_NAME.azurewebsites.net" 2>/dev/null | head -1

# Test API endpoints
echo ""
echo "🔗 Testing API endpoints..."
echo "SELECTALLPLAYER:"
curl -s "https://$FUNCTION_APP_NAME.azurewebsites.net/api/SELECTALLPLAYER" | head -c 200
echo ""

echo "SELECTEVENTS:"
curl -s "https://$FUNCTION_APP_NAME.azurewebsites.net/api/SELECTEVENTS" | head -c 200
echo ""

# Check if functions are listed (requires publish profile)
echo ""
echo "📝 To check detailed logs:"
echo "1. Go to Azure Portal → Function Apps → $FUNCTION_APP_NAME"
echo "2. Monitor → Log stream (live logs)"
echo "3. Functions → Check if your functions are listed"
echo ""
echo "🌐 Function App URL: https://$FUNCTION_APP_NAME.azurewebsites.net"
echo "🔧 Kudu Console: https://$FUNCTION_APP_NAME.scm.azurewebsites.net"