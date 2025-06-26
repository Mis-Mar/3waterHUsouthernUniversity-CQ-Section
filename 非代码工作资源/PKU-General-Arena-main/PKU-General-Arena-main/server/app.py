from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from engine.GameManager import GeneralsGame # 引入游戏管理类, 修改文件名时要看这里的import路径
import json
import os
import asyncio # 处理异步操作，实现并发

app = FastAPI()

# 存储活跃游戏，后续会更新到数据库中
active_games = {}
game_connections = {} # 记录每个game_id的所有websocket连接

# 显式指定静态文件目录
app.mount("/static", StaticFiles(directory="static"), name="static")

'''把 static 目录下的前端页面、样式、JS 文件作为静态资源对外提供
前端可以通过 /static/ 路径访问这些文件。'''

@app.get("/") # 当路由为'/'（首次执行时）运行该修饰下的所有函数
async def read_root():
    return FileResponse(os.path.join('static', 'index.html'))

'''访问 / 时返回前端主页面 index.html'''

@app.websocket("/ws/{game_id}/{player_id}")
async def websocket_endpoint(websocket: WebSocket, game_id: str, player_id: int):

    '''前端通过 WebSocket 连接到 /ws/{game_id}/{player_id}。
    如果 game_id 不存在，则创建一个新的 GeneralsGame 实例。
    连接后，服务器发送当前游戏状态给客户端。
    服务器循环接收客户端消息（如移动指令），处理后更新游戏状态，并把新状态发回客户端。
    如果客户端断开连接，会清理对应的游戏。'''

    await websocket.accept()
    
    # 创建或加入游戏
    if game_id not in active_games:
        active_games[game_id] = GeneralsGame(size=15)
        print(f"创建新游戏: {game_id}")
    
    game = active_games[game_id]
    
    # 关键：初始化连接集合并加入当前连接
    if game_id not in game_connections:
        game_connections[game_id] = set()
    game_connections[game_id].add(websocket)

    try:
        # 发送初始状态
        await websocket.send_json({
            "type": "init",
            "state": game.get_state(),
            "player": player_id
        })
        
        while True:
            data = await websocket.receive_json()
            if data["type"] == "move":
                from_pos = tuple(data["from"])
                to_pos = tuple(data["to"])
                success = game.move(player_id, from_pos, to_pos)
                if success:
                    # 广播给所有连接
                    for ws in list(game_connections[game_id]):
                        await ws.send_json({
                            "type": "update",
                            "state": game.get_state()
                        })
    
    except WebSocketDisconnect:
        print(f"玩家 {player_id} 断开连接")
        # 注销连接
        if game_id in game_connections:
            game_connections[game_id].discard(websocket)
            if not game_connections[game_id]:
                del game_connections[game_id]
        # 清理空游戏
        if game_id in active_games and not game_connections.get(game_id):
            del active_games[game_id]
            print(f'已清空游戏：{game_id}')



@app.on_event("startup")
async def start_turn_scheduler():
    async def turn_scheduler():
        while True:
            await asyncio.sleep(0.7)
            for game_id, game in list(active_games.items()):
                game.next_turn()
                # 广播新状态
                if game_id in game_connections:
                    for ws in list(game_connections[game_id]):
                        try:
                            await ws.send_json({
                                "type": "update",
                                "state": game.get_state()
                            })
                        except Exception:
                            pass  # 忽略断开的连接
    asyncio.create_task(turn_scheduler())