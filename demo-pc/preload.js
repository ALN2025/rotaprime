const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('rotaDemo', {
  platform: process.platform,
});
