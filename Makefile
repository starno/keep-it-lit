#
# Makefile for generating gerbers and pngs.
# Tested on Advanced Circuits barebones, should work for 33 each, 
# gerbmerge, and Advanced Circuits. Pngs used for the fab modules 
# and the modella. 
#
# Copyright (C) 2011 Andy Bardagjy. 
#
# This makefile is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This makefile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
# Andy Bardagjy
# June 21, 2011
#
# Atommann
# Sept. 30, 2014 - use another kind of file extension scheme
# Oct. 13, 2014 - milling layer (GML)
# Apr. 16, 2015 - Export the drill file with 2:4 precision for Eagle-7.2. Device is EXCELLON_24.
#
# TODO
# Interesting bug, if there are no holes on the board, the script fails
# because no drd file is generated, so... I touch an empty drd file 
# so the build doesn't fail. This is kinda a kluge...
# 
# If there's no dimension layer, the build fails...
# 
# I should add document export: sch, brd
#

PROJECT?=keep-it-lit

WHITE?= \#FFFFFF
BLACK?= \#000000
DPI?= 2400

all: gerbers fab parts

# Gerber Top Layer
$(PROJECT).GTL: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GTL $(PROJECT).brd Top Pads Vias

# Gerber Bottom Layer
$(PROJECT).GBL: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GBL $(PROJECT).brd Bottom Pads Vias

# Gerber Top Solder Mask
$(PROJECT).GTS: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GTS $(PROJECT).brd tStop

# Gerber Bottom Solder Mask
$(PROJECT).GBS: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GBS $(PROJECT).brd bStop

# Gerber Top Overlay
$(PROJECT).GTO: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GTO $(PROJECT).brd Dimension tPlace tNames tValues

# Gerber Bottom Overlay
$(PROJECT).GBO: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GBO $(PROJECT).brd Dimension bPlace bNames bValues

# Gerber Top Paste Mask
$(PROJECT).GTP: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GTP $(PROJECT).brd tCream

# Gerber Bottom Paste Mask
$(PROJECT).GBP: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GBP $(PROJECT).brd bCream

# Drills Xcellon
$(PROJECT).TXT: $(PROJECT).brd
	# FIXME This is the drd hack (see top of file)
	rm -f $(PROJECT).TXT
	touch $(PROJECT).TXT
	eagle -X -dEXCELLON_24 -o$(PROJECT).TXT $(PROJECT).brd Drills Holes

# Gerber KeepOut/Outline
$(PROJECT).GKO: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GKO $(PROJECT).brd Dimension

# Gerber Milling/cut-out
$(PROJECT).GML: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).GML $(PROJECT).brd Milling

# Fab reference Frame
$(PROJECT).ref: $(PROJECT).brd
	eagle -X -dGERBER_RS274X -o$(PROJECT).ref $(PROJECT).brd Reference



# Top Copper PNG
# So you *can* do this with eagle commands, but the holes don't work out right.
# Gotta use gerbv to do this
#$(PROJECT)_cmp.png: $(PROJECT).brd
#	eagle -C "ratsnest; display none Top Pads Vias; export image $(PROJECT)_cmp.png monochrome 600; quit;" $(PROJECT).brd
#	convert $(PROJECT)_cmp.png -negate $(PROJECT)_cmp.png
$(PROJECT)_cmp.png: gerbers
	gerbv gerbers/$(PROJECT).cmp gerbers/$(PROJECT).ref -b$(BLACK) -f$(WHITE) -f$(BLACK) -B0 -D$(DPI) -o $(PROJECT)_cmp.png -xpng
	convert $(PROJECT)_cmp.png -colorspace gray +dither -colors 2 -normalize $(PROJECT)_cmp.png
	convert $(PROJECT)_cmp.png -mattecolor black -frame 25x25 $(PROJECT)_cmp.png
	convert $(PROJECT)_cmp.png -strip $(PROJECT)_cmp.png
	convert $(PROJECT)_cmp.png -units PixelsPerInch -density $(DPI) $(PROJECT)_cmp.png
	#convert $(PROJECT)_cmp.png -colorspace RGB $(PROJECT)_cmp.png
	convert $(PROJECT)_cmp.png -type TrueColormatte PNG32:$(PROJECT)_cmp.png

# Bottom Copper PNG
# So you *can* do this with eagle commands, but the holes don't work out right.
# Gotta use gerbv to do this
$(PROJECT)_sol.png: gerbers
	gerbv gerbers/$(PROJECT).sol gerbers/$(PROJECT).ref -b$(BLACK) -f$(WHITE) -f$(BLACK) -B0 -D$(DPI) -o $(PROJECT)_sol.png -xpng
	convert $(PROJECT)_sol.png -colorspace gray +dither -colors 2 -normalize $(PROJECT)_sol.png
	convert $(PROJECT)_sol.png -mattecolor black -frame 25x25 $(PROJECT)_sol.png
	convert $(PROJECT)_sol.png -strip $(PROJECT)_sol.png
	convert $(PROJECT)_sol.png -units PixelsPerInch -density $(DPI) $(PROJECT)_sol.png
	#convert $(PROJECT)_sol.png -colorspace RGB $(PROJECT)_sol.png
	convert $(PROJECT)_sol.png -type TrueColormatte PNG32:$(PROJECT)_sol.png

# BOARD PNG
$(PROJECT)_bor.png: gerbers
	gerbv gerbers/$(PROJECT).bor gerbers/$(PROJECT).ref -b$(WHITE) -f$(BLACK) -f$(WHITE) -B0 -D$(DPI) -o $(PROJECT)_bor.png -xpng
	convert $(PROJECT)_bor.png -colorspace gray +dither -colors 2 -normalize $(PROJECT)_bor.png
	convert $(PROJECT)_bor.png -mattecolor white -frame 25x25 $(PROJECT)_bor.png
	convert $(PROJECT)_bor.png -strip $(PROJECT)_bor.png
	convert $(PROJECT)_bor.png -fill black    -floodfill +0+0 white $(PROJECT)_bor.png
	convert $(PROJECT)_bor.png -units PixelsPerInch -density $(DPI) $(PROJECT)_bor.png
	#convert $(PROJECT)_bor.png -colorspace RGB $(PROJECT)_bor.png
	convert $(PROJECT)_bor.png -type TrueColormatte PNG32:$(PROJECT)_bor.png


# Drills PNG
# So you *can* do this with eagle commands, but the holes don't work out right.
# Gotta use gerbv to do this
#$(PROJECT)_drd.png: $(PROJECT).brd
#	eagle -C "ratsnest; display none Drills Holes Dimension; export image $(PROJECT)_drd.png monochrome 600; quit;" $(PROJECT).brd
$(PROJECT)_drd.png: gerbers
	gerbv gerbers/$(PROJECT).drd gerbers/$(PROJECT).ref -b$(WHITE) -f$(BLACK) -f$(WHITE) -B0 -D$(DPI) -o $(PROJECT)_drd.png -xpng
	convert $(PROJECT)_drd.png -colorspace gray +dither -colors 2 -normalize $(PROJECT)_drd.png
	convert $(PROJECT)_drd.png -mattecolor white -frame 25x25 $(PROJECT)_drd.png
	convert $(PROJECT)_drd.png -strip $(PROJECT)_drd.png
	convert $(PROJECT)_drd.png -units PixelsPerInch -density $(DPI) $(PROJECT)_drd.png
	#convert $(PROJECT)_drd.png -colorspace RGB $(PROJECT)_drd.png
	convert $(PROJECT)_drd.png -type TrueColormatte PNG32:$(PROJECT)_drd.png

gerbers: $(PROJECT).GTL $(PROJECT).GBL $(PROJECT).GTS $(PROJECT).GBS $(PROJECT).GTO $(PROJECT).GBO $(PROJECT).TXT $(PROJECT).GKO $(PROJECT).ref $(PROJECT).GTP $(PROJECT).GBP $(PROJECT).GML
	mkdir -p gerbers
	mv $(PROJECT).{GKO,GTL,TXT,dri,gpi,GBL,GTS,GBS,GTO,GBO,GTP,GBP,GML,ref} gerbers/
	zip gerbers/$(PROJECT)_fab.zip gerbers/*.{GKO,TXT,GTL,GBL,GTS,GBS,GTO,GBO,GTP,GBP,GML}
	zip gerbers/$(PROJECT)_barebones.zip gerbers/*.{GKO,TXT,GTL,GBL,GML}

# fab: $(PROJECT)_cmp.png $(PROJECT)_drd.png $(PROJECT)_sol.png
fab: $(PROJECT)_cmp.png $(PROJECT)_drd.png $(PROJECT)_sol.png $(PROJECT)_bor.png
	mkdir -p fab
	# mv $(PROJECT){_cmp.png,_sol.png,_drd.png} fab/
	mv $(PROJECT){_cmp.png,_drd.png,_sol.png,_bor.png} fab/
	rm -rf gerbers

view: gerbers
	#gerbv gerbers/$(PROJECT).{bor,drd,stc,plc,cmp,sts,pls,sol} &
	gerbv gerbers/$(PROJECT).{GKO,TXT,GTL,GBL,GTS,GBS,GTO,GBO,GTP,GBP,GML,ref} &

parts: $(PROJECT).sch
	eagle -C "export partlist $(PROJECT).txt; quit;" $(PROJECT).sch
	eagle_parts $(PROJECT).csv $(PROJECT).txt
	mkdir parts
	mv $(PROJECT).{csv,txt} parts

clean:
	rm -rf $(PROJECT).{csv,txt,GKO,GTL,TXT,dri,gpi,GBL,zip,png,path,GBS,GTS,GTO,GBO,GTP,GBP,GML}
	rm -rf *#*
	rm -rf gerbers fab parts
