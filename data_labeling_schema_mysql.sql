-- ============================================
-- DATA LABELING PLATFORM - COMPLETE SQL DDL
-- MySQL 8.0+
-- ============================================

-- ============================================
-- RBAC & USER MANAGEMENT
-- ============================================

CREATE TABLE roles (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    name VARCHAR(50) UNIQUE NOT NULL,
    permissions JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    role VARCHAR(50) DEFAULT 'annotator',
    expertise JSON,
    hourly_rate DECIMAL(10,2),
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    last_login_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id CHAR(36) NOT NULL,
    role_id CHAR(36) NOT NULL,
    project_id CHAR(36) NULL,
    assigned_by CHAR(36),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    UNIQUE KEY unique_user_role_project (user_id, role_id, project_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- ============================================
-- PROJECT CONFIGURATION
-- ============================================

CREATE TABLE projects (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    owner_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    data_type VARCHAR(50) CHECK (data_type IN ('text', 'image', 'audio', 'video', 'multimodal')),
    label_type VARCHAR(50) CHECK (label_type IN ('classification', 'detection', 'segmentation', 'ner', 'keypoints')),
    scale_estimate INT,
    timeline_start DATE,
    timeline_end DATE,
    quality_definition JSON,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (owner_id) REFERENCES users(id)
);

-- Add FK for user_roles after projects created
ALTER TABLE user_roles 
ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
ADD FOREIGN KEY (assigned_by) REFERENCES users(id);

CREATE TABLE guidelines (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    title VARCHAR(255),
    content TEXT,
    examples JSON,
    kpis JSON,
    version INT DEFAULT 1,
    created_by CHAR(36),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE label_classes (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#000000',
    definition TEXT,
    parent_id CHAR(36),
    shortcut_key CHAR(1),
    order_index INT DEFAULT 0,
    metadata JSON,
    UNIQUE KEY unique_project_label (project_id, name),
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES label_classes(id)
);

-- ============================================
-- DATA STORAGE
-- ============================================

CREATE TABLE datasets (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(10) DEFAULT '1.0',
    stats JSON,
    status VARCHAR(20) DEFAULT 'preparing' CHECK (status IN ('preparing', 'ready', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);

CREATE TABLE assets (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    dataset_id CHAR(36) NOT NULL,
    filename VARCHAR(500) NOT NULL,
    filepath VARCHAR(1000) NOT NULL,
    file_size BIGINT,
    checksum VARCHAR(64),
    metadata JSON,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    batch_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'annotated', 'reviewing', 'approved', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE
);

-- ============================================
-- WORKFLOW
-- ============================================

CREATE TABLE tasks (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    dataset_id CHAR(36) NOT NULL,
    name VARCHAR(255),
    type VARCHAR(50) CHECK (type IN ('annotation', 'review', 'qc')),
    config JSON,
    workflow JSON,
    assignment_rules JSON,
    priority INT DEFAULT 2 CHECK (priority IN (1, 2, 3)),
    due_date TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id) ON DELETE CASCADE
);

CREATE TABLE assignments (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    task_id CHAR(36) NOT NULL,
    user_id CHAR(36) NOT NULL,
    asset_ids JSON,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'reassigned')),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ============================================
-- ANNOTATION & REVIEW
-- ============================================

CREATE TABLE annotations (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    asset_id CHAR(36) NOT NULL,
    task_id CHAR(36) NOT NULL,
    annotator_id CHAR(36) NOT NULL,
    label_data JSON NOT NULL,
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
    time_spent_seconds INT,
    version INT DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'approved', 'rejected', 'revised')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    FOREIGN KEY (annotator_id) REFERENCES users(id)
);

CREATE TABLE reviews (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    annotation_id CHAR(36) NOT NULL,
    reviewer_id CHAR(36) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('approved', 'rejected', 'needs_correction')),
    feedback TEXT,
    score FLOAT CHECK (score >= 0 AND score <= 100),
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (annotation_id) REFERENCES annotations(id) ON DELETE CASCADE,
    FOREIGN KEY (reviewer_id) REFERENCES users(id)
);

CREATE TABLE annotation_versions (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    annotation_id CHAR(36) NOT NULL,
    version_num INT NOT NULL,
    label_data JSON NOT NULL,
    changed_by CHAR(36) NOT NULL,
    change_reason VARCHAR(255),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (annotation_id) REFERENCES annotations(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id)
);

-- ============================================
-- QUALITY CONTROL
-- ============================================

CREATE TABLE quality_controls (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    qc_type VARCHAR(50) NOT NULL CHECK (qc_type IN ('random_sampling', 'golden_set', 'consensus', 'iaa')),
    annotation_id CHAR(36),
    checker_id CHAR(36),
    status VARCHAR(20) CHECK (status IN ('pass', 'fail', 'needs_review')),
    score DECIMAL(5,2),
    feedback TEXT,
    error_type VARCHAR(50) CHECK (error_type IN ('misunderstanding', 'operation', 'format')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (annotation_id) REFERENCES annotations(id),
    FOREIGN KEY (checker_id) REFERENCES users(id)
);

CREATE TABLE golden_sets (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    asset_id CHAR(36) NOT NULL,
    expert_id CHAR(36),
    ground_truth JSON NOT NULL,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    used_for VARCHAR(50) CHECK (used_for IN ('qc', 'training', 'benchmark')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE,
    FOREIGN KEY (expert_id) REFERENCES users(id)
);

-- ============================================
-- REPORTING & EXPORT
-- ============================================

CREATE TABLE reports (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('progress', 'quality', 'productivity', 'error_analysis')),
    generated_by CHAR(36),
    data JSON NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (generated_by) REFERENCES users(id)
);

CREATE TABLE exports (
    id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
    project_id CHAR(36) NOT NULL,
    dataset_id CHAR(36),
    format VARCHAR(50) NOT NULL CHECK (format IN ('jsonl', 'csv', 'coco', 'yolo', 'pascal_voc')),
    filters JSON,
    file_path VARCHAR(1000),
    stats JSON,
    checksum VARCHAR(64),
    exported_by CHAR(36),
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,
    FOREIGN KEY (dataset_id) REFERENCES datasets(id),
    FOREIGN KEY (exported_by) REFERENCES users(id)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_user_roles_user ON user_roles(user_id);
CREATE INDEX idx_user_roles_project ON user_roles(project_id);

CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_projects_status ON projects(status);

CREATE INDEX idx_assets_dataset ON assets(dataset_id);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_batch ON assets(batch_id);

CREATE INDEX idx_tasks_dataset ON tasks(dataset_id);
CREATE INDEX idx_tasks_status ON tasks(status);

CREATE INDEX idx_assignments_task ON assignments(task_id);
CREATE INDEX idx_assignments_user ON assignments(user_id);
CREATE INDEX idx_assignments_status ON assignments(status);

CREATE INDEX idx_annotations_asset ON annotations(asset_id);
CREATE INDEX idx_annotations_task ON annotations(task_id);
CREATE INDEX idx_annotations_annotator ON annotations(annotator_id);
CREATE INDEX idx_annotations_status ON annotations(status);

CREATE INDEX idx_reviews_annotation ON reviews(annotation_id);
CREATE INDEX idx_reviews_reviewer ON reviews(reviewer_id);

CREATE INDEX idx_qc_project ON quality_controls(project_id);
CREATE INDEX idx_golden_project ON golden_sets(project_id);
CREATE INDEX idx_reports_project ON reports(project_id);
CREATE INDEX idx_exports_project ON exports(project_id);

-- ============================================
-- DEFAULT DATA
-- ============================================

INSERT INTO roles (name, permissions) VALUES
('admin', '{"all": true}'),
('project_owner', '{"projects": ["create", "read", "update", "delete"], "users": ["read"]}'),
('annotator', '{"annotations": ["create", "read", "update"], "tasks": ["read"]}'),
('reviewer', '{"reviews": ["create", "read", "update"], "annotations": ["read"]}'),
('qc', '{"quality_controls": ["create", "read", "update"], "annotations": ["read"]}');
