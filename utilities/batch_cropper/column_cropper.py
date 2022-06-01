from wand.image import Image
import os

inputs = sorted(os.listdir('Inputs'))
outputs = os.listdir('Outputs')
toprocess = inputs[len(outputs):]

for fn in toprocess:
   with Image(filename='Inputs/'+fn) as i:
     i.crop(left=int(i.width/6),top=int(i.height/16),width=int(i.width/6),height=int(i.height/16*15))
     i.save(filename='Outputs/'+fn)
#     i.save(filename='Outputs/'+fn.replace('.tif','.png'))
