import {
  Button,
  Form,
  Input,
  InputNumber,
  Modal,
  Select,
  Space,
  Switch,
  Table,
  Tabs,
  Tag,
  message,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { Database, KeyRound, Plus, RefreshCcw, RotateCcw } from 'lucide-react';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  type AdminDashboard,
  type InterviewQuestion,
  type KnowledgeCategory,
  type KnowledgePoint,
  type PointFormValues,
  type QuestionFormValues,
  adminApi,
} from './api';

const storageKeys = {
  baseUrl: 'offer-hunter-admin.base-url',
  token: 'offer-hunter-admin.token',
};

export default function App() {
  const [messageApi, contextHolder] = message.useMessage();
  const [baseUrl, setBaseUrl] = useState(
    () => localStorage.getItem(storageKeys.baseUrl) || 'http://localhost:8080',
  );
  const [token, setToken] = useState(
    () => localStorage.getItem(storageKeys.token) || '',
  );
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [dashboard, setDashboard] = useState<AdminDashboard>();
  const [categories, setCategories] = useState<KnowledgeCategory[]>([]);
  const [points, setPoints] = useState<KnowledgePoint[]>([]);
  const [questions, setQuestions] = useState<InterviewQuestion[]>([]);
  const [loading, setLoading] = useState(false);
  const [pointModalOpen, setPointModalOpen] = useState(false);
  const [questionModalOpen, setQuestionModalOpen] = useState(false);
  const [pointForm] = Form.useForm<PointFormValues>();
  const [questionForm] = Form.useForm<QuestionFormValues>();

  const api = useMemo(() => adminApi(baseUrl, token), [baseUrl, token]);

  const saveConnection = useCallback(() => {
    localStorage.setItem(storageKeys.baseUrl, baseUrl);
    localStorage.setItem(storageKeys.token, token);
    messageApi.success('Connection saved');
  }, [baseUrl, messageApi, token]);

  const loadAll = useCallback(async () => {
    if (!token) {
      return;
    }
    setLoading(true);
    try {
      const [nextDashboard, nextCategories, nextPoints, nextQuestions] =
        await Promise.all([
          api.dashboard(),
          api.categories(),
          api.points(),
          api.questions(),
        ]);
      setDashboard(nextDashboard);
      setCategories(nextCategories);
      setPoints(nextPoints);
      setQuestions(nextQuestions);
    } catch (error) {
      messageApi.error(readError(error));
    } finally {
      setLoading(false);
    }
  }, [api, messageApi, token]);

  useEffect(() => {
    void loadAll();
  }, [loadAll]);

  async function login() {
    setLoading(true);
    try {
      const result = await api.login(username, password);
      setToken(result.accessToken);
      localStorage.setItem(storageKeys.token, result.accessToken);
      messageApi.success(`Signed in as ${result.admin.username}`);
    } catch (error) {
      messageApi.error(readError(error));
    } finally {
      setLoading(false);
    }
  }

  async function seedDefaultContent() {
    setLoading(true);
    try {
      const result = await api.seedDefaultContent();
      messageApi.success(
        `Seeded ${result.points} points and ${result.questions} questions`,
      );
      await loadAll();
    } catch (error) {
      messageApi.error(readError(error));
    } finally {
      setLoading(false);
    }
  }

  async function submitPoint(values: PointFormValues) {
    try {
      await api.upsertPoint(values);
      setPointModalOpen(false);
      pointForm.resetFields();
      await loadAll();
      messageApi.success('Point saved');
    } catch (error) {
      messageApi.error(readError(error));
    }
  }

  async function submitQuestion(values: QuestionFormValues) {
    try {
      await api.upsertQuestion(values);
      setQuestionModalOpen(false);
      questionForm.resetFields();
      await loadAll();
      messageApi.success('Question saved');
    } catch (error) {
      messageApi.error(readError(error));
    }
  }

  const pointColumns: ColumnsType<KnowledgePoint> = [
    {
      title: 'Title',
      dataIndex: 'title',
      render: (value, record) => (
        <div>
          <strong>{value}</strong>
          <p className="muted">{record.summary}</p>
        </div>
      ),
    },
    {
      title: 'Category',
      dataIndex: 'categoryId',
      width: 160,
      render: (value) => categoryTitle(categories, value),
    },
    {
      title: 'Difficulty',
      dataIndex: 'difficulty',
      width: 120,
      render: (value) => <Tag>{value}</Tag>,
    },
    {
      title: 'Questions',
      dataIndex: 'questionCount',
      width: 110,
    },
    {
      title: 'Published',
      width: 130,
      render: (_, record) => (
        <Switch
          checked={record.published}
          checkedChildren="On"
          unCheckedChildren="Off"
          onChange={(checked) =>
            api
              .publishPoint(record.pointId, checked)
              .then(loadAll)
              .catch((error) => messageApi.error(readError(error)))
          }
        />
      ),
    },
  ];

  const questionColumns: ColumnsType<InterviewQuestion> = [
    {
      title: 'Question',
      dataIndex: 'title',
      render: (value, record) => (
        <div>
          <strong>{value}</strong>
          <p className="muted">{record.prompt}</p>
        </div>
      ),
    },
    {
      title: 'Point',
      dataIndex: 'pointId',
      width: 220,
      render: (value) => pointTitle(points, value),
    },
    {
      title: 'Difficulty',
      dataIndex: 'difficulty',
      width: 120,
      render: (value) => <Tag>{value}</Tag>,
    },
    {
      title: 'Frequency',
      dataIndex: 'frequency',
      width: 120,
      render: (value) => <Tag color="blue">{value}</Tag>,
    },
    {
      title: 'Published',
      width: 130,
      render: (_, record) => (
        <Switch
          checked={record.published}
          checkedChildren="On"
          unCheckedChildren="Off"
          onChange={(checked) =>
            api
              .publishQuestion(record.questionId, checked)
              .then(loadAll)
              .catch((error) => messageApi.error(readError(error)))
          }
        />
      ),
    },
  ];

  return (
    <main className="app-shell">
      {contextHolder}
      <header className="topbar">
        <div>
          <h1>Offer Hunter Admin</h1>
          <p>Content operations for knowledge points, interview questions, and default seeds.</p>
        </div>
        <Space wrap>
          <Input
            className="base-url"
            value={baseUrl}
            onChange={(event) => setBaseUrl(event.target.value)}
            prefix={<Database size={16} />}
          />
          <Input.Password
            className="token-input"
            value={token}
            onChange={(event) => setToken(event.target.value)}
            placeholder="Admin token"
            prefix={<KeyRound size={16} />}
          />
          <Button onClick={saveConnection}>Save</Button>
          <Button icon={<RefreshCcw size={16} />} loading={loading} onClick={loadAll}>
            Refresh
          </Button>
        </Space>
      </header>

      {!token && (
        <section className="login-strip">
          <Input
            placeholder="Admin username"
            value={username}
            onChange={(event) => setUsername(event.target.value)}
          />
          <Input.Password
            placeholder="Password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
          />
          <Button type="primary" onClick={login} loading={loading}>
            Sign in
          </Button>
        </section>
      )}

      <section className="metrics">
        <Metric label="Version" value={dashboard?.activeVersion || '-'} />
        <Metric label="Points" value={`${dashboard?.publishedPoints ?? 0}/${dashboard?.points ?? 0}`} />
        <Metric label="Questions" value={`${dashboard?.publishedQuestions ?? 0}/${dashboard?.questions ?? 0}`} />
        <Metric label="Categories" value={dashboard?.categories ?? 0} />
      </section>

      <Tabs
        className="work-tabs"
        items={[
          {
            key: 'points',
            label: 'Knowledge Points',
            children: (
              <section className="workspace-panel">
                <Toolbar
                  title="Knowledge points"
                  onCreate={() => {
                    pointForm.resetFields();
                    setPointModalOpen(true);
                  }}
                  onSeed={seedDefaultContent}
                />
                <Table
                  rowKey="pointId"
                  loading={loading}
                  dataSource={points}
                  columns={pointColumns}
                  pagination={{ pageSize: 8 }}
                />
              </section>
            ),
          },
          {
            key: 'questions',
            label: 'Questions',
            children: (
              <section className="workspace-panel">
                <Toolbar
                  title="Interview questions"
                  onCreate={() => {
                    questionForm.resetFields();
                    setQuestionModalOpen(true);
                  }}
                  onSeed={seedDefaultContent}
                />
                <Table
                  rowKey="questionId"
                  loading={loading}
                  dataSource={questions}
                  columns={questionColumns}
                  pagination={{ pageSize: 8 }}
                />
              </section>
            ),
          },
        ]}
      />

      <Modal
        title="Knowledge point"
        open={pointModalOpen}
        onCancel={() => setPointModalOpen(false)}
        onOk={() => pointForm.submit()}
        destroyOnHidden
      >
        <Form form={pointForm} layout="vertical" onFinish={submitPoint}>
          <Form.Item name="categoryId" label="Category" rules={[{ required: true }]}>
            <Select options={categories.map((item) => ({ label: item.title, value: item.categoryId }))} />
          </Form.Item>
          <Form.Item name="title" label="Title" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="summary" label="Summary">
            <Input.TextArea rows={3} />
          </Form.Item>
          <Form.Item name="detail" label="Detail">
            <Input.TextArea rows={5} />
          </Form.Item>
          <Form.Item name="difficulty" label="Difficulty" initialValue="medium">
            <Select options={difficultyOptions} />
          </Form.Item>
          <Form.Item name="estimatedMinutes" label="Estimated minutes" initialValue={8}>
            <InputNumber min={1} max={120} />
          </Form.Item>
          <Form.Item name="tags" label="Tags">
            <Select mode="tags" tokenSeparators={[',']} />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Interview question"
        open={questionModalOpen}
        onCancel={() => setQuestionModalOpen(false)}
        onOk={() => questionForm.submit()}
        destroyOnHidden
      >
        <Form form={questionForm} layout="vertical" onFinish={submitQuestion}>
          <Form.Item name="categoryId" label="Category" rules={[{ required: true }]}>
            <Select options={categories.map((item) => ({ label: item.title, value: item.categoryId }))} />
          </Form.Item>
          <Form.Item name="pointId" label="Knowledge point">
            <Select
              allowClear
              showSearch
              optionFilterProp="label"
              options={points.map((item) => ({ label: item.title, value: item.pointId }))}
            />
          </Form.Item>
          <Form.Item name="title" label="Title" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="prompt" label="Prompt" rules={[{ required: true }]}>
            <Input.TextArea rows={4} />
          </Form.Item>
          <Form.Item name="answer" label="Standard answer">
            <Input.TextArea rows={5} />
          </Form.Item>
          <Form.Item name="difficulty" label="Difficulty" initialValue="medium">
            <Select options={difficultyOptions} />
          </Form.Item>
          <Form.Item name="frequency" label="Frequency" initialValue="medium">
            <Select options={frequencyOptions} />
          </Form.Item>
          <Form.Item name="tags" label="Tags">
            <Select mode="tags" tokenSeparators={[',']} />
          </Form.Item>
        </Form>
      </Modal>
    </main>
  );
}

function Metric({ label, value }: { label: string; value: string | number }) {
  return (
    <div className="metric">
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function Toolbar({
  title,
  onCreate,
  onSeed,
}: {
  title: string;
  onCreate: () => void;
  onSeed: () => void;
}) {
  return (
    <div className="toolbar">
      <h2>{title}</h2>
      <Space>
        <Button icon={<RotateCcw size={16} />} onClick={onSeed}>
          Seed defaults
        </Button>
        <Button type="primary" icon={<Plus size={16} />} onClick={onCreate}>
          Add
        </Button>
      </Space>
    </div>
  );
}

const difficultyOptions = ['easy', 'medium', 'hard'].map((value) => ({
  label: value,
  value,
}));

const frequencyOptions = ['low', 'medium', 'high'].map((value) => ({
  label: value,
  value,
}));

function categoryTitle(categories: KnowledgeCategory[], categoryId: string) {
  return categories.find((item) => item.categoryId === categoryId)?.title || categoryId;
}

function pointTitle(points: KnowledgePoint[], pointId: string) {
  return points.find((item) => item.pointId === pointId)?.title || pointId || '-';
}

function readError(error: unknown) {
  return error instanceof Error ? error.message : 'Request failed';
}
