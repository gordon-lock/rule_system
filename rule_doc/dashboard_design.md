# 主仪表板页面设计

## 页面概述
主仪表板是用户登录后的首页，提供数据质量系统的整体概览，包括关键指标、最近活动、快速操作等。

## 页面布局

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Header                                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ Sidebar │ Main Content                                                     │
│         │                                                                   │
│ Dashboard│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐     │
│ Rules    │ │   Quality Score │ │  Active Rules   │ │ Failed Rules    │     │
│ Reports  │ │     85.2%       │ │      1,234      │ │       23        │     │
│ Templates│ │   ▲ +2.1%       │ │   ▲ +12%        │ │   ▼ -5%         │     │
│ Settings │ └─────────────────┘ └─────────────────┘ └─────────────────┘     │
│         │                                                                   │
│         │ ┌─────────────────────────────────────────────────────────────┐   │
│         │ │                    Quality Trend                            │   │
│         │ │  ┌─────────────────────────────────────────────────────┐   │   │
│         │ │  │                                                     │   │   │
│         │ │  │  85.2% ──────────────────────────────────────────   │   │   │
│         │ │  │                                                     │   │   │
│         │ │  └─────────────────────────────────────────────────────┘   │   │
│         │ └─────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         │ ┌─────────────────────────────────────────────────────────────┐   │
│         │ │                    Recent Activities                        │   │
│         │ │ ┌─────────────────┐ ┌─────────────────────────────────────┐ │   │
│         │ │ │ Quick Actions   │ │ Activity Feed                        │ │   │
│         │ │ │                 │ │                                     │ │   │
│         │ │ │ • Create Rule   │ │ • Rule "user_id_unique" failed      │ │   │
│         │ │ │ • View Reports  │ │ • New table "orders" added           │ │   │
│         │ │ │ • Test Template │ │ • Quality score improved by 2.1%    │ │   │
│         │ │ │ • Manage Users  │ │ • Template "email_validation" used  │ │   │
│         │ │ └─────────────────┘ └─────────────────────────────────────┘ │   │
│         │ └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 详细组件设计

### 1. 顶部导航栏 (Header)

```html
<header class="header">
  <div class="header-left">
    <div class="logo">
      <img src="/logo.svg" alt="Data Quality System" />
      <span class="logo-text">Data Quality</span>
    </div>
  </div>
  
  <div class="header-center">
    <div class="search-bar">
      <input type="text" placeholder="Search tables, rules, or reports..." />
      <button class="search-btn">
        <svg><!-- Search icon --></svg>
      </button>
    </div>
  </div>
  
  <div class="header-right">
    <div class="notifications">
      <button class="notification-btn">
        <svg><!-- Bell icon --></svg>
        <span class="notification-badge">3</span>
      </button>
    </div>
    
    <div class="user-menu">
      <img src="/avatar.jpg" alt="User Avatar" class="avatar" />
      <span class="username">John Doe</span>
      <svg><!-- Dropdown icon --></svg>
    </div>
  </div>
</header>
```

### 2. 侧边导航栏 (Sidebar)

```html
<nav class="sidebar">
  <div class="nav-section">
    <div class="nav-item active">
      <svg><!-- Dashboard icon --></svg>
      <span>Dashboard</span>
    </div>
    
    <div class="nav-item">
      <svg><!-- Rules icon --></svg>
      <span>Rules</span>
      <span class="badge">1,234</span>
    </div>
    
    <div class="nav-item">
      <svg><!-- Templates icon --></svg>
      <span>Templates</span>
      <span class="badge">45</span>
    </div>
    
    <div class="nav-item">
      <svg><!-- Reports icon --></svg>
      <span>Reports</span>
    </div>
  </div>
  
  <div class="nav-section">
    <div class="nav-item">
      <svg><!-- Tables icon --></svg>
      <span>Tables</span>
    </div>
    
    <div class="nav-item">
      <svg><!-- Users icon --></svg>
      <span>Users</span>
    </div>
    
    <div class="nav-item">
      <svg><!-- Settings icon --></svg>
      <span>Settings</span>
    </div>
  </div>
</nav>
```

### 3. 关键指标卡片 (KPI Cards)

```html
<div class="kpi-grid">
  <!-- 质量评分卡片 -->
  <div class="kpi-card quality-score">
    <div class="kpi-header">
      <h3>Overall Quality Score</h3>
      <svg><!-- Info icon --></svg>
    </div>
    
    <div class="kpi-value">
      <span class="score">85.2%</span>
      <span class="trend positive">▲ +2.1%</span>
    </div>
    
    <div class="kpi-chart">
      <div class="progress-ring">
        <svg viewBox="0 0 120 120">
          <circle class="progress-bg" cx="60" cy="60" r="54"/>
          <circle class="progress-fill" cx="60" cy="60" r="54" 
                  stroke-dasharray="339.292" stroke-dashoffset="50.894"/>
        </svg>
        <div class="progress-text">85.2%</div>
      </div>
    </div>
    
    <div class="kpi-footer">
      <span>Last updated: 2 minutes ago</span>
    </div>
  </div>
  
  <!-- 活跃规则卡片 -->
  <div class="kpi-card active-rules">
    <div class="kpi-header">
      <h3>Active Rules</h3>
      <svg><!-- Rules icon --></svg>
    </div>
    
    <div class="kpi-value">
      <span class="count">1,234</span>
      <span class="trend positive">▲ +12%</span>
    </div>
    
    <div class="kpi-breakdown">
      <div class="breakdown-item">
        <span class="label">Tables</span>
        <span class="value">156</span>
      </div>
      <div class="breakdown-item">
        <span class="label">Templates</span>
        <span class="value">45</span>
      </div>
    </div>
  </div>
  
  <!-- 失败规则卡片 -->
  <div class="kpi-card failed-rules">
    <div class="kpi-header">
      <h3>Failed Rules</h3>
      <svg><!-- Alert icon --></svg>
    </div>
    
    <div class="kpi-value">
      <span class="count">23</span>
      <span class="trend negative">▼ -5%</span>
    </div>
    
    <div class="kpi-actions">
      <button class="btn-secondary">View Details</button>
      <button class="btn-primary">Fix Issues</button>
    </div>
  </div>
</div>
```

### 4. 质量趋势图表

```html
<div class="chart-card">
  <div class="chart-header">
    <h3>Quality Trend (Last 30 Days)</h3>
    <div class="chart-controls">
      <select class="time-range">
        <option value="7">Last 7 days</option>
        <option value="30" selected>Last 30 days</option>
        <option value="90">Last 90 days</option>
      </select>
      <button class="btn-secondary">Export</button>
    </div>
  </div>
  
  <div class="chart-container">
    <canvas id="qualityTrendChart"></canvas>
  </div>
  
  <div class="chart-legend">
    <div class="legend-item">
      <span class="legend-color" style="background: var(--quality-excellent)"></span>
      <span>Excellent (90-100%)</span>
    </div>
    <div class="legend-item">
      <span class="legend-color" style="background: var(--quality-good)"></span>
      <span>Good (70-89%)</span>
    </div>
    <div class="legend-item">
      <span class="legend-color" style="background: var(--quality-fair)"></span>
      <span>Fair (50-69%)</span>
    </div>
    <div class="legend-item">
      <span class="legend-color" style="background: var(--quality-poor)"></span>
      <span>Poor (0-49%)</span>
    </div>
  </div>
</div>
```

### 5. 快速操作和活动流

```html
<div class="dashboard-bottom">
  <div class="quick-actions-card">
    <div class="card-header">
      <h3>Quick Actions</h3>
    </div>
    
    <div class="quick-actions-grid">
      <button class="quick-action-btn">
        <svg><!-- Plus icon --></svg>
        <span>Create Rule</span>
      </button>
      
      <button class="quick-action-btn">
        <svg><!-- Template icon --></svg>
        <span>New Template</span>
      </button>
      
      <button class="quick-action-btn">
        <svg><!-- Test icon --></svg>
        <span>Test Rules</span>
      </button>
      
      <button class="quick-action-btn">
        <svg><!-- Report icon --></svg>
        <span>Generate Report</span>
      </button>
      
      <button class="quick-action-btn">
        <svg><!-- Import icon --></svg>
        <span>Import Rules</span>
      </button>
      
      <button class="quick-action-btn">
        <svg><!-- Settings icon --></svg>
        <span>System Settings</span>
      </button>
    </div>
  </div>
  
  <div class="activity-feed-card">
    <div class="card-header">
      <h3>Recent Activities</h3>
      <button class="btn-secondary">View All</button>
    </div>
    
    <div class="activity-list">
      <div class="activity-item error">
        <div class="activity-icon">
          <svg><!-- Error icon --></svg>
        </div>
        <div class="activity-content">
          <div class="activity-title">Rule "user_id_unique" failed</div>
          <div class="activity-details">Table: users, Partition: 2024-12-19</div>
          <div class="activity-time">2 minutes ago</div>
        </div>
        <button class="activity-action">View</button>
      </div>
      
      <div class="activity-item info">
        <div class="activity-icon">
          <svg><!-- Info icon --></svg>
        </div>
        <div class="activity-content">
          <div class="activity-title">New table "orders" added</div>
          <div class="activity-details">Database: analytics, Owner: data_team</div>
          <div class="activity-time">15 minutes ago</div>
        </div>
        <button class="activity-action">Configure</button>
      </div>
      
      <div class="activity-item success">
        <div class="activity-icon">
          <svg><!-- Success icon --></svg>
        </div>
        <div class="activity-content">
          <div class="activity-title">Quality score improved by 2.1%</div>
          <div class="activity-details">Overall score: 85.2%</div>
          <div class="activity-time">1 hour ago</div>
        </div>
        <button class="activity-action">Details</button>
      </div>
      
      <div class="activity-item info">
        <div class="activity-icon">
          <svg><!-- Template icon --></svg>
        </div>
        <div class="activity-content">
          <div class="activity-title">Template "email_validation" used</div>
          <div class="activity-details">Applied to 5 tables</div>
          <div class="activity-time">2 hours ago</div>
        </div>
        <button class="activity-action">View</button>
      </div>
    </div>
  </div>
</div>
```

## 响应式设计

### 桌面端 (>1024px)
- 侧边栏固定显示
- 三列KPI卡片布局
- 图表和活动流并排显示

### 平板端 (768px-1024px)
- 侧边栏可折叠
- 两列KPI卡片布局
- 图表和活动流垂直排列

### 移动端 (<768px)
- 侧边栏隐藏，通过汉堡菜单访问
- 单列KPI卡片布局
- 所有内容垂直排列

## 交互设计

### 1. 悬停效果
- KPI卡片悬停时显示阴影
- 按钮悬停时改变背景色
- 活动项悬停时高亮显示

### 2. 点击交互
- KPI卡片点击跳转到详细页面
- 快速操作按钮点击打开相应功能
- 活动项点击查看详细信息

### 3. 实时更新
- 质量评分每5分钟自动更新
- 活动流实时推送新活动
- 失败规则数量实时变化

## 可访问性设计

### 1. 键盘导航
- Tab键可以在所有交互元素间导航
- Enter键激活按钮和链接
- 方向键在图表中导航

### 2. 屏幕阅读器
- 所有图表提供alt文本描述
- 状态变化提供ARIA通知
- 语义化HTML结构

### 3. 颜色对比度
- 所有文字与背景对比度符合WCAG标准
- 状态颜色有足够的对比度
- 提供高对比度模式选项 