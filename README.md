
# Starting on local machine

```
foreman start
```

# Starting in Vagrant VM

```
vagrant up
vagrant ssh
cd app
npm start
```

# Getting the card data
To update the card data, use the `sync` script as shown below. Make sure to check that the set symbol images for any added sets are correct.

```
npm run sync
```

# Creating the set symbol sprite
In order to make the card viewer use less network resources, all of the set symbol images are sprited. The actual images (and data) are not stored in Git but can be generated using the following command.

```
npm run createSetSymbolSprite
```

# Creating the mana cost symbol sprite
Same as the set symbol sprite but for the mana symbols.

```
npm run createManaCostsSymbolSprite
```

# Magic the Gathering Fan Site License
This website is not affiliated with, endorsed, sponsored, or specifically approved by Wizards of the Coast LLC. This website may use the trademarks and other intellectual property of Wizards of the Coast LLC, which is permitted under Wizards' Fan Site Policy http://company.wizards.com/fankit. For example, MAGIC: THE GATHERING® is a trademark[s] of Wizards of the Coast. For more information about Wizards of the Coast or any of Wizards' trademarks or other intellectual property, please visit their website at (www.wizards.com).

# Credits
This website contains references to the following projects

* MTGJson.com
* MTGImages.com