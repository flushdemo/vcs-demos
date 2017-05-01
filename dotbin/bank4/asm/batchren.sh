for file in *.s; do
    mv "$file" "`basename "$file" .s`.inc"
done