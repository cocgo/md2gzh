const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.static('.'));

// 下载目录
const DOWNLOAD_DIR = path.join(__dirname, 'downloaded');
if (!fs.existsSync(DOWNLOAD_DIR)) {
    fs.mkdirSync(DOWNLOAD_DIR);
}

// 已下载的任务ID（防止重复下载）
const downloadedTasks = new Set();

// 生成图片（代理 API，解决跨域）
app.post('/api/generate', async (req, res) => {
    try {
        const { apiKey, body } = req.body;
        console.log(`[${new Date().toLocaleString()}] 开始生成请求，提示词: ${body.input?.prompt?.substring(0, 50)}...`);

        const response = await axios({
            method: 'POST',
            url: 'https://api.reachapi.ai/v1/images/create',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json'
            },
            data: body
        });

        console.log(`[${new Date().toLocaleString()}] 任务已提交，task_id: ${response.data.task_id}`);
        res.json(response.data);
    } catch (err) {
        console.log(`[${new Date().toLocaleString()}] 请求失败: ${err.message}`);
        res.status(500).json({
            code: 500,
            msg: err.message
        });
    }
});

// 查询任务
app.post('/api/task', async (req, res) => {
    try {
        const { apiKey, taskId } = req.body;
        const response = await axios({
            method: 'GET',
            url: `https://api.reachapi.ai/v1/tasks/${taskId}`,
            headers: {
                'Authorization': `Bearer ${apiKey}`
            }
        });

        // 如果生成成功，自动下载图片
        const data = response.data;
        if (data.status === 'success' && data.data?.[0]?.url && !downloadedTasks.has(taskId)) {
            downloadedTasks.add(taskId);
            const imgUrl = data.data[0].url;
            console.log(`[${new Date().toLocaleString()}] 任务完成，task_id: ${taskId}，图片地址: ${imgUrl}`);
            await downloadImage(imgUrl, DOWNLOAD_DIR);
        } else if (data.status === 'success') {
            console.log(`[${new Date().toLocaleString()}] 任务已完成（已下载过），task_id: ${taskId}`);
        }

        res.json(data);
    } catch (err) {
        console.log(`[${new Date().toLocaleString()}] 查询任务失败: ${err.message}`);
        res.status(500).json({ status: 'error' });
    }
});

// 下载图片到本地
async function downloadImage(url, dir) {
    try {
        const res = await axios({
            url,
            responseType: 'stream'
        });

        const timestamp = Date.now();
        const ext = res.headers['content-type']?.split('/')[1] || 'png';
        const filename = `ai_${timestamp}.${ext}`;
        const savePath = path.join(dir, filename);

        const writer = fs.createWriteStream(savePath);
        res.data.pipe(writer);

        return new Promise((resolve) => {
            writer.on('finish', () => {
                console.log(`[${new Date().toLocaleString()}] 图片已下载: ${filename}`);
                resolve();
            });
        });
    } catch (e) {
        console.log(`[${new Date().toLocaleString()}] 下载失败:`, e.message);
    }
}

// 启动
const PORT = 2828;
app.listen(PORT, () => {
    console.log(`✅ 本地服务已启动：http://localhost:${PORT}`);
});