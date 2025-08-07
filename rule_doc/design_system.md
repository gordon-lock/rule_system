# 大数据质量管理系统 - 设计系统规范

## 1. 设计理念

### 1.1 设计原则
- **简洁明了**: 复杂的数据质量概念通过直观的界面呈现
- **高效操作**: 减少用户操作步骤，提升工作效率
- **信息层次**: 清晰的信息架构，重要信息突出显示
- **一致性**: 统一的视觉语言和交互模式
- **可访问性**: 支持不同设备和用户群体的使用需求

### 1.2 设计风格
- **现代简约**: 扁平化设计，减少视觉干扰
- **数据驱动**: 以数据展示为核心，图表和可视化为主
- **专业可靠**: 体现企业级产品的专业性和可靠性

## 2. 色彩系统

### 2.1 主色调
```css
/* 主色 - 科技蓝 */
--primary-color: #2563eb;
--primary-light: #3b82f6;
--primary-dark: #1d4ed8;

/* 辅助色 - 成功绿 */
--success-color: #10b981;
--success-light: #34d399;
--success-dark: #059669;

/* 警告色 - 警告橙 */
--warning-color: #f59e0b;
--warning-light: #fbbf24;
--warning-dark: #d97706;

/* 错误色 - 错误红 */
--error-color: #ef4444;
--error-light: #f87171;
--error-dark: #dc2626;
```

### 2.2 中性色
```css
/* 文字颜色 */
--text-primary: #111827;
--text-secondary: #6b7280;
--text-disabled: #9ca3af;

/* 背景颜色 */
--bg-primary: #ffffff;
--bg-secondary: #f9fafb;
--bg-tertiary: #f3f4f6;

/* 边框颜色 */
--border-light: #e5e7eb;
--border-medium: #d1d5db;
--border-dark: #9ca3af;
```

### 2.3 状态颜色
```css
/* 质量评分颜色 */
--quality-excellent: #10b981; /* 90-100分 */
--quality-good: #3b82f6;      /* 70-89分 */
--quality-fair: #f59e0b;      /* 50-69分 */
--quality-poor: #ef4444;      /* 0-49分 */

/* 规则状态颜色 */
--status-active: #10b981;
--status-draft: #6b7280;
--status-testing: #f59e0b;
--status-error: #ef4444;
```

## 3. 字体系统

### 3.1 字体族
```css
--font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
```

### 3.2 字体大小
```css
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.125rem;   /* 18px */
--text-xl: 1.25rem;    /* 20px */
--text-2xl: 1.5rem;    /* 24px */
--text-3xl: 1.875rem;  /* 30px */
--text-4xl: 2.25rem;   /* 36px */
```

### 3.3 字重
```css
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

## 4. 间距系统

### 4.1 基础间距
```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
--space-20: 5rem;     /* 80px */
```

## 5. 组件规范

### 5.1 按钮组件
```css
/* 主要按钮 */
.btn-primary {
  background: var(--primary-color);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: var(--font-medium);
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

/* 次要按钮 */
.btn-secondary {
  background: var(--bg-secondary);
  color: var(--text-primary);
  border: 1px solid var(--border-medium);
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: var(--font-medium);
  cursor: pointer;
  transition: all 0.2s;
}

/* 危险按钮 */
.btn-danger {
  background: var(--error-color);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 0.5rem;
  font-weight: var(--font-medium);
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}
```

### 5.2 卡片组件
```css
.card {
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: 0.75rem;
  padding: var(--space-6);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.card-header {
  border-bottom: 1px solid var(--border-light);
  padding-bottom: var(--space-4);
  margin-bottom: var(--space-4);
}

.card-title {
  font-size: var(--text-lg);
  font-weight: var(--font-semibold);
  color: var(--text-primary);
  margin: 0;
}
```

### 5.3 表格组件
```css
.table {
  width: 100%;
  border-collapse: collapse;
}

.table th {
  background: var(--bg-secondary);
  padding: var(--space-3) var(--space-4);
  text-align: left;
  font-weight: var(--font-medium);
  color: var(--text-secondary);
  border-bottom: 1px solid var(--border-light);
}

.table td {
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--border-light);
  color: var(--text-primary);
}
```

### 5.4 状态标签
```css
.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
  font-size: var(--text-sm);
  font-weight: var(--font-medium);
  display: inline-block;
}

.status-success {
  background: var(--success-light);
  color: var(--success-dark);
}

.status-warning {
  background: var(--warning-light);
  color: var(--warning-dark);
}

.status-error {
  background: var(--error-light);
  color: var(--error-dark);
}

.status-info {
  background: var(--primary-light);
  color: var(--primary-dark);
}
```

## 6. 图标系统

### 6.1 图标库
- **Heroicons**: 主要图标库
- **Lucide Icons**: 补充图标库
- **自定义图标**: 数据质量专用图标

### 6.2 图标尺寸
```css
--icon-xs: 1rem;    /* 16px */
--icon-sm: 1.25rem; /* 20px */
--icon-md: 1.5rem;  /* 24px */
--icon-lg: 2rem;    /* 32px */
--icon-xl: 2.5rem;  /* 40px */
```

## 7. 响应式断点

```css
--breakpoint-sm: 640px;
--breakpoint-md: 768px;
--breakpoint-lg: 1024px;
--breakpoint-xl: 1280px;
--breakpoint-2xl: 1536px;
```

## 8. 动画和过渡

### 8.1 过渡时间
```css
--transition-fast: 0.15s;
--transition-normal: 0.3s;
--transition-slow: 0.5s;
```

### 8.2 缓动函数
```css
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
```

## 9. 阴影系统

```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
--shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.1);
```

## 10. 可访问性

### 10.1 颜色对比度
- 确保所有文字与背景的对比度符合WCAG 2.1 AA标准
- 主要文字对比度 ≥ 4.5:1
- 大文字对比度 ≥ 3:1

### 10.2 键盘导航
- 所有交互元素支持键盘导航
- 提供清晰的焦点指示器
- 支持Tab键顺序导航

### 10.3 屏幕阅读器
- 提供适当的ARIA标签
- 语义化HTML结构
- 描述性链接文本 