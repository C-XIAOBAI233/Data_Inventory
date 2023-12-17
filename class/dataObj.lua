require('lib')
DataObj={}

function DataObj:new(obj)
	local obj = obj or {}
	setmetatable(obj,self)
	self.__index=self
	return obj
end

---return fileName/table
local function findDataFile(path,key,findAll)
	local findAll=findAll or false
	local fileTable={}

	---find key
	for k,fileName in pairs(fs.list(path)) do
		if fileName:sub(1,#key+1)==key..'_' then
			if not findAll then
				return fileName
			else
				table.insert(fileTable,fileName)
			end
		end
	end

	if findAll then
		return fileTable
	else
		return nil
	end
end

---file name format:<key>_<timestamp>.<suffix>
---path should end by '/'
function DataObj:init(key,permission,path,suffix)
	self.key=key
	self.suffix=suffix or nil
	self.timestamp=0
	self.permission=permission or {}
	self.path=path

	---is file existing(ignore timestamp)
	local fileName=findDataFile(path,key)

	---get fileName
	if not fileName then
		---create file
		local newTimestamp=lib.get_timestamp()
		local tempFileObj=io.open(self.path..self.key..
			'_'..newTimestamp..'.'..self.suffix,
			'w')
		self.timestamp=newTimestamp
		tempFileObj:close()
	elseif fileName:find('%.') then
		self.suffix=fileName:sub(fileName:find('%.')+1,#fileName)
		self.timestamp=fileName:sub(fileName:find('_')+1,fileName:find('%.')-1)
	else
		self.suffix=fileName:sub(fileName:find('_')+1,#fileName)
	end
end

function DataObj:getFileName(timestamp)
	timestamp=timestamp or self.timestamp
	if self.suffix then
		return self.key..'_'..timestamp..'.'..self.suffix
	else
		return self.key..'_'..timestamp
	end
end

function DataObj:getFilePath()
	return self.path..self:getFileName()
end

function DataObj:read()
	local fileObj=fs.open(self:getFilePath(),'r')
	local data=fileObj.readAll()
	fileObj.close()
	return data
end

function DataObj:write(data,dump)
	local newTimestamp=lib.get_timestamp()
	local fileObj=io.open(self.path..self:getFileName(newTimestamp),'w')
	fileObj:write(data)
	fileObj:close()
	if dump and newTimestamp~=self.timestamp then
		fs.move(self:getFilePath(),self.path..'dump/'..
			self:getFileName())
	elseif newTimestamp~=self.timestamp then
		fs.delete(self:getFilePath())
	end

	self.timestamp=newTimestamp
end

function DataObj:append(data,dump)
	data=textutils.unserializeJSON(data) 
	if self.suffix=='json' and data then
		local oriData=textutils.unserializeJSON(self:read())
		lib.merge_tables(oriData,data)
		self:write(oriData,dump)
	else
		local fileObj=io.open(self:getFilePath(),'a')
		fileObj:write(data,dump)
		fileObj:close()
	end
end

function DataObj:delete(dump)
	if dump then
		fs.move(self:getFilePath(),self.path..'dump/'..
			self:getFileName())
	else
		fs.delete(self:getFilePath())
	end
end

function DataObj:getInfo()
	local info={}
	info.timestamp=self.timestamp
	info.permission=self.permission
	info.suffix=self.suffix
	return self.key,info
end

function DataObj:getPermission(id)
	return self.permission[id]
end

function DataObj:setPermission(id,level)
	self.permission[id]=tonumber(level)
end

return DataObj
