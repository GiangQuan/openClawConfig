-- ============================================
-- DATA LABELING PLATFORM - COMPLETE SQL DDL
-- PostgreSQL 14+ (Recommended)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- RBAC & USER MANAGEMENT
-- ============================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    avatar_url VARCHAR(500),
    role VARCHAR(50) DEFAULT 'annotator',
    expertise TEXT[],
    hourly_rate DECIMAL(10,2),
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES users(id),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    UNIQUE(user_id, role_id, project_id)
);

-- ============================================
-- PROJECT CONFIGURATION
-- ============================================

CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    data_type VARCHAR(50) CHECK (data_type IN ('text', 'image', 'audio', 'video', 'multimodal')),
    label_type VARCHAR(50) CHECK (label_type IN ('classification', 'detection', 'segmentation', 'ner', 'keypoints')),
    scale_estimate INTEGER,
    timeline_start DATE,
    timeline_end DATE,
    quality_definition JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE guidelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    title VARCHAR(255),
    content TEXT,
    examples JSONB DEFAULT '{}',
    kpis JSONB DEFAULT '{}',
    version INTEGER DEFAULT 1,
    created_by UUID REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE label_classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#000000',
    definition TEXT,
    parent_id UUID REFERENCES label_classes(id),
    shortcut_key CHAR(1),
    order_index INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    UNIQUE(project_id, name)
);

-- ============================================
-- DATA STORAGE
-- ============================================

CREATE TABLE datasets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(10) DEFAULT '1.0',
    stats JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'preparing' CHECK (status IN ('preparing', 'ready', 'archived')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    filename VARCHAR(500) NOT NULL,
    filepath VARCHAR(1000) NOT NULL,
    file_size BIGINT,
    checksum VARCHAR(64),
    metadata JSONB DEFAULT '{}',
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    batch_id VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'annotated', 'reviewing', 'approved', 'rejected')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- WORKFLOW
-- ============================================

CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dataset_id UUID NOT NULL REFERENCES datasets(id) ON DELETE CASCADE,
    name VARCHAR(255),
    type VARCHAR(50) CHECK (type IN ('annotation', 'review', 'qc')),
    config JSONB DEFAULT '{}',
    workflow JSONB DEFAULT '["annotator", "reviewer"]',
    assignment_rules JSONB DEFAULT '{}',
    priority INTEGER DEFAULT 2 CHECK (priority IN (1, 2, 3)),
    due_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    asset_ids UUID[],
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'reassigned')),
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    notes TEXT
);

-- ============================================
-- ANNOTATION & REVIEW
-- ============================================

CREATE TABLE annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    annotator_id UUID NOT NULL REFERENCES users(id),
    label_data JSONB NOT NULL,
    confidence FLOAT CHECK (confidence >= 0 AND confidence <= 1),
    time_spent_seconds INTEGER,
    version INTEGER DEFAULT 1,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'approved', 'rejected', 'revised')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    annotation_id UUID NOT NULL REFERENCES annotations(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('approved', 'rejected', 'needs_correction')),
    feedback TEXT,
    score FLOAT CHECK (score >= 0 AND score <= 100),
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE annotation_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    annotation_id UUID NOT NULL REFERENCES annotations(id) ON DELETE CASCADE,
    version_num INTEGER NOT NULL,
    label_data JSONB NOT NULL,
    changed_by UUID NOT NULL REFERENCES users(id),
    change_reason VARCHAR(255),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- QUALITY CONTROL
-- ============================================

CREATE TABLE quality_controls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    qc_type VARCHAR(50) NOT NULL CHECK (qc_type IN ('random_sampling', 'golden_set', 'consensus', 'iaa')),
    annotation_id UUID REFERENCES annotations(id),
    checker_id UUID REFERENCES users(id),
    status VARCHAR(20) CHECK (status IN ('pass', 'fail', 'needs_review')),
    score DECIMAL(5,2),
    feedback TEXT,
    error_type VARCHAR(50) CHECK (error_type IN ('misunderstanding', 'operation', 'format')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE golden_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    expert_id UUID REFERENCES users(id),
    ground_truth JSONB NOT NULL,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    used_for VARCHAR(50) CHECK (used_for IN ('qc', 'training', 'benchmark')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- REPORTING & EXPORT
-- ============================================

CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('progress', 'quality', 'productivity', 'error_analysis')),
    generated_by UUID REFERENCES users(id),
    data JSONB NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE exports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    dataset_id UUID REFERENCES datasets(id),
    format VARCHAR(50) NOT NULL CHECK (format IN ('jsonl', 'csv', 'coco', 'yolo', 'pascal_voc')),
    filters JSONB DEFAULT '{}',
    file_path VARCHAR(1000),
    stats JSONB DEFAULT '{}',
    checksum VARCHAR(64),
    exported_by UUID REFERENCES users(id),
    exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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
-- TRIGGERS FOR AUDIT
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_projects_updated_at
    BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_annotations_updated_at
    BEFORE UPDATE ON annotations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- DEFAULT DATA
-- ============================================

INSERT INTO roles (name, permissions) VALUES
('admin', '{"all": true}'),
('project_owner', '{"projects": ["create", "read", "update", "delete"], "users": ["read"]}'),
('annotator', '{"annotations": ["create", "read", "update"], "tasks": ["read"]}'),
('reviewer', '{"reviews": ["create", "read", "update"], "annotations": ["read"]}'),
('qc', '{"quality_controls": ["create", "read", "update"], "annotations": ["read"]}');
