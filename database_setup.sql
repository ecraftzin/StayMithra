-- Create follow requests table
CREATE TABLE IF NOT EXISTS public.follow_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  requested_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(requester_id, requested_id)
);

-- Create follows table (for accepted follows)
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id)
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('follow_request', 'follow_accepted', 'post_like', 'post_comment', 'campaign_like', 'campaign_comment', 'post_share', 'campaign_share')),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create post comments table
CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create campaign comments table
CREATE TABLE IF NOT EXISTS public.campaign_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID NOT NULL REFERENCES public.campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add media_type column to campaigns table
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS media_type VARCHAR(20) DEFAULT 'image' CHECK (media_type IN ('image', 'video', 'mixed'));
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS video_urls TEXT[];

-- Enable RLS
ALTER TABLE public.follow_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for follow_requests
CREATE POLICY "Users can view follow requests involving them" ON public.follow_requests FOR SELECT USING (
  auth.uid() = requester_id OR auth.uid() = requested_id
);
CREATE POLICY "Users can create follow requests" ON public.follow_requests FOR INSERT WITH CHECK (auth.uid() = requester_id);
CREATE POLICY "Users can update follow requests they received" ON public.follow_requests FOR UPDATE USING (auth.uid() = requested_id);

-- RLS Policies for follows
CREATE POLICY "Follows are publicly readable" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can create follows" ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can delete own follows" ON public.follows FOR DELETE USING (auth.uid() = follower_id);

-- RLS Policies for notifications
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "System can create notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- RLS Policies for post_comments
CREATE POLICY "Post comments are publicly readable" ON public.post_comments FOR SELECT USING (true);
CREATE POLICY "Users can create post comments" ON public.post_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own post comments" ON public.post_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own post comments" ON public.post_comments FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for campaign_comments
CREATE POLICY "Campaign comments are publicly readable" ON public.campaign_comments FOR SELECT USING (true);
CREATE POLICY "Users can create campaign comments" ON public.campaign_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own campaign comments" ON public.campaign_comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own campaign comments" ON public.campaign_comments FOR DELETE USING (auth.uid() = user_id);

-- Create functions to increment comment counts
CREATE OR REPLACE FUNCTION increment_post_comments(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_campaign_comments(campaign_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE campaigns SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = campaign_id;
END;
$$ LANGUAGE plpgsql;

-- Create function to increment post shares
CREATE OR REPLACE FUNCTION increment_post_shares(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE posts SET shares_count = COALESCE(shares_count, 0) + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql;

-- Add comments_count and shares_count columns to posts if they don't exist
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0;

-- Add comments_count column to campaigns if it doesn't exist
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

-- Create shares table for tracking shares
CREATE TABLE IF NOT EXISTS public.shares (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content_type VARCHAR(20) NOT NULL CHECK (content_type IN ('post', 'campaign')),
  content_id UUID NOT NULL,
  shared_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for shares
ALTER TABLE public.shares ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shares
CREATE POLICY "Shares are publicly readable" ON public.shares FOR SELECT USING (true);
CREATE POLICY "Users can create shares" ON public.shares FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can view own shares" ON public.shares FOR SELECT USING (auth.uid() = user_id);
