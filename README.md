# shaders-reshade
several shaders for reshade 4

MMBR is short of MouseMotionBlur, Ashader which can blurs moving things.
totally based on mouse moving, it didn't effects on moving that caused by runing(WASD).
it relies on QUINT shaders, but written by Aestheticses.
only works when be upper than ADOF shaders.

some statements benefit from qUINT shader “ADOF” . 
https://github.com/martymcmodding/qUINT/blob/master/Shaders/qUINT_dof.fx

the code is work with Assassin's Creed  Odyssey.
If it didn't work, try to remove (1- color.alpha).

"float depth = saturate(log(qUINT::linear_depth(IN.txcoord.xy)*10+0.92) ) * (1-centerTap.a);"
	//(1-centerTap.a) only work with Assassins Creed Odyssey"
"currentWeight *= (0.055 + max(currentTap.r+currentTap.g+currentTap.b-2.4,0))* saturate(1-currentTap.a); "
	//(1-currentTap.a) only work with Assassins Creed Odyssey"
