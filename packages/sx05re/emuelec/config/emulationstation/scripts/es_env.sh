HOME=/storage
#LD_LIBRARY_PATH=/emuelec/lib:/usr/lib:/usr/lib/pulseaudio
PATH=/emuelec/scripts:/emuelec/bin:/usr/bin:/usr/sbin:/storage/.config/emulationstation/scripts:/usr/bin/batocera
#SDL_AUDIODRIVER=alsa
# 让 SDL 载入大 gamecontrollerdb,配合 ES 放行的 SDL 自动映射 fallback,
# 使几千款已收录手柄插上即用(自动生成位置对齐的 Xbox 式映射),无需跑设定精灵。
SDL_GAMECONTROLLERCONFIG_FILE=/usr/config/SDL-GameControllerDB/gamecontrollerdb.txt
