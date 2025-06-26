document.addEventListener('DOMContentLoaded', () => {
    const gameBoard = document.getElementById('game-board');
    const turnCounter = document.getElementById('turn-counter');
    const newGameBtn = document.getElementById('new-game');
    
    let gameId = generateGameId();
    let playerId = Math.random() > 0.5 ? 1 : 2;
    let selectedCell = null;
    let socket = null;
    let lastState = null;
    
    // 生成随机游戏ID
    function generateGameId() {
        return 'game-' + Math.random().toString(36).substr(2, 9);
    }
    
    // 连接WebSocket
    // 修改连接地址为当前主机

    newGameBtn.addEventListener('click', () => {
        gameId = generateGameId();
        playerId = Math.random() > 0.5 ? 1 : 2;
        // 清空棋盘和状态
        gameBoard.innerHTML = '';
        selectedCell = null;
        lastState = null;
        turnCounter.textContent = '0';
        connectWebSocket();
    });
    
    function connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const host = window.location.host;
        socket = new WebSocket(`${protocol}//${host}/ws/${gameId}/${playerId}`);
    
        socket.onopen = () => {
            // 可以在这里做一些连接成功的提示
        };
    
        socket.onmessage = (event) => {
            const msg = JSON.parse(event.data);
            if (msg.type === "init" || msg.type === "update") {
                renderBoard(msg.state);
            }
        };
    
        socket.onclose = () => {
            // 连接关闭时的处理
        };
    
        socket.onerror = (err) => {
            // 错误处理
            console.error("WebSocket error:", err);
        };
    }
    
    
    // 渲染游戏板
    function renderBoard(state) {
        lastState = state;
        gameBoard.innerHTML = '';
        turnCounter.textContent = state.turn || 0;
        // ...步数显示...
    
        for (let x = 0; x < state.board.length; x++) {
            for (let y = 0; y < state.board[x].length; y++) {
                const cellType = state.board[x][y];
                const armyCount = state.armies[x][y];
                const cell = document.createElement('div');
                cell.className = 'cell';
                cell.setAttribute('data-x', x);
                cell.setAttribute('data-y', y);
    
                // 恢复选中状态
                if (selectedCell && selectedCell.x === x && selectedCell.y === y) {
                    cell.classList.add('selected');
                }
    
                let imgSrc = '';
                if (cellType === -1) {
                    imgSrc = '/static/img/mountain.png';
                } else if (cellType === 1) {
                    imgSrc = '/static/img/player1.png';
                } else if (cellType === 2) {
                    imgSrc = '/static/img/player2.png';
                } else {
                    imgSrc = '/static/img/empty.png';
                }
                cell.innerHTML = `<img src="${imgSrc}" class="cell-img" alt="">` +
                    (armyCount > 0 ? `<span class="army-count">${armyCount}</span>` : '');
    
                // 绑定点击事件
                cell.addEventListener('click', () => handleCellClick(x, y, cellType));
    
                gameBoard.appendChild(cell);
            }
        }
    }
    
    
    // 处理单元格点击
    function handleCellClick(x, y, cellType) {
        // 选择己方单位
        if (cellType === playerId) {
            if (selectedCell && (selectedCell.x !== x || selectedCell.y !== y)) {
                const fromX = selectedCell.x, fromY = selectedCell.y;
                // 只有兵力大于1才允许移动
                if (lastState.armies[fromX][fromY] > 1) {
                    const moveData = {
                        type: "move",
                        from: [fromX, fromY],
                        to: [x, y]
                    };
                    socket.send(JSON.stringify(moveData));
                }
                clearSelection();
            } else {
                clearSelection();
                selectedCell = {x, y};
                const cell = document.querySelector(`.cell[data-x="${x}"][data-y="${y}"]`);
                cell.classList.add('selected');
            }
        }
        // 移动到非山地的其他格
        else if (selectedCell && cellType !== -1) {
            const moveData = {
                type: "move",
                from: [selectedCell.x, selectedCell.y],
                to: [x, y]
            };
            socket.send(JSON.stringify(moveData));
            clearSelection();
        }
    }
    
    
    // 清除选择
    function clearSelection() {
        document.querySelectorAll('.cell.selected').forEach(cell => {
            cell.classList.remove('selected');
        });
        selectedCell = null;
    }
    
    // 新游戏按钮
    newGameBtn.addEventListener('click', () => {
        gameId = generateGameId();
        playerId = Math.random() > 0.5 ? 1 : 2;
        connectWebSocket();
    });
    
    // 初始连接
    connectWebSocket();
});