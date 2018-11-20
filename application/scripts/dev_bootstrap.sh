#!/bin/sh
virtualenv venv
pip install -r requirements.txt

echo ""
echo ""
echo "#################"
echo "To run server locally for development:"
echo "source venv/bin/activate"
echo "python app/main.py"
